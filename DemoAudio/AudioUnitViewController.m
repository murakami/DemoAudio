//
//  AudioUnitViewController.m
//  DemoAudio
//
//  Created by 村上 幸雄 on 11/09/20.
//  Copyright 2011年 ビッツ有限会社. All rights reserved.
//

#import "AudioUnitViewController.h"

static AudioStreamBasicDescription AUCanonicalASBD(Float64 sampleRate, UInt32 channel);
static AudioStreamBasicDescription CanonicalASBD(Float64 sampleRate, UInt32 channel);
static OSStatus MyAURenderCallack(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber,
                                  UInt32 inNumberFrames, AudioBufferList *ioData);

@interface AudioUnitViewController ()
- (void)prepareBuffer;
- (void)prepareAUGraph;
- (AudioStreamBasicDescription)auCanonicalASBDSampleRate:(Float64)sampleRate channel:(UInt32)channel;
- (AudioStreamBasicDescription)canonicalASBDSampleRate:(Float64)sampleRate channel:(UInt32)channel;
- (void)write:(UInt32)inNumberFrames data:(AudioBufferList *)ioData;
@end

@implementation AudioUnitViewController

@synthesize recAUGraph = __recAUGraph;
@synthesize isRecording = __isRecording;
@synthesize audioUnitOutputFormat = __audioUnitOutputFormat;
@synthesize buffer = __buffer;
@synthesize startingSampleCount = __startingSampleCount;
@synthesize maxSampleCount = __maxSampleCount;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    DBGMSG(@"%s", __func__);
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    DBGMSG(@"%s", __func__);
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    DBGMSG(@"%s", __func__);
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    /*
    AudioSessionInitialize(NULL, NULL, NULL, NULL);
    UInt32 nChannels = 0;
    UInt32 size = sizeof(nChannels);
    AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareInputNumberChannels,
                            &size,
                            &nChannels);
    NSLog(@"Input nChannels:%u", (unsigned int)nChannels);
    AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareOutputNumberChannels,
                            &size,
                            &nChannels);
    NSLog(@"Output nChannels:%u", (unsigned int)nChannels);
    */

    [self prepareBuffer];

    self.isRecording = NO;
    [self prepareAUGraph];
}

- (void)viewDidUnload
{
    DBGMSG(@"%s", __func__);
    
    if (self.isRecording)   [self stop:nil];
    AUGraphUninitialize(self.recAUGraph);
    AUGraphClose(self.recAUGraph);
    DisposeAUGraph(self.recAUGraph);
    
    free(self.buffer);
    self.buffer = NULL;
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)record:(id)sender
{
    DBGMSG(@"%s", __func__);
    if (self.isRecording)   return;
    
    AUGraphStart(self.recAUGraph);
    AUGraphAddRenderNotify(self.recAUGraph, MyAURenderCallack, self);
    self.isRecording = YES;
}

- (IBAction)play:(id)sender
{
    DBGMSG(@"%s", __func__);
}

- (IBAction)stop:(id)sender
{
    DBGMSG(@"%s", __func__);
    if (! self.isRecording)   return;

    AUGraphRemoveRenderNotify(self.recAUGraph, MyAURenderCallack, self);
    AUGraphStop(self.recAUGraph);
    self.isRecording = NO;
}

- (void)prepareBuffer
{
    DBGMSG(@"%s", __func__);
    
    uint32_t    bytesPerSample = sizeof(AudioUnitSampleType);
    uint32_t    sec = 4;
    self.startingSampleCount = 0;
    self.maxSampleCount = (44100 * sec);
    self.buffer = malloc(self.maxSampleCount * bytesPerSample);
}

- (void)prepareAUGraph
{
    DBGMSG(@"%s", __func__);
    AUNode      remoteIONode;
    AudioUnit   remoteIOUnit;
    
    NewAUGraph(&__recAUGraph);
    AUGraphOpen(self.recAUGraph);
    
    AudioComponentDescription   cd;
    cd.componentType            = kAudioUnitType_Output;
    cd.componentSubType         = kAudioUnitSubType_RemoteIO;
    cd.componentManufacturer    = kAudioUnitManufacturer_Apple;
    cd.componentFlags           = 0;
    cd.componentFlagsMask       = 0;
    
    AUGraphAddNode(self.recAUGraph, &cd, &remoteIONode);
    AUGraphNodeInfo(self.recAUGraph, remoteIONode, NULL, &remoteIOUnit);
    
    UInt32  flag = 1;
    AudioUnitSetProperty(remoteIOUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &flag, sizeof(flag));
    
    AudioStreamBasicDescription audioFormat = [self canonicalASBDSampleRate:44100.0 channel:1];
    AudioUnitSetProperty(remoteIOUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &audioFormat, sizeof(AudioStreamBasicDescription));
    AudioUnitSetProperty(remoteIOUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &audioFormat, sizeof(AudioStreamBasicDescription));
    
    //AUGraphConnectNodeInput(self.recAUGraph, remoteIONode, 1, remoteIONode, 0);
    AUGraphInitialize(self.recAUGraph);
}

- (AudioStreamBasicDescription)auCanonicalASBDSampleRate:(Float64)sampleRate channel:(UInt32)channel
{
    return AUCanonicalASBD(sampleRate, channel);
}

- (AudioStreamBasicDescription)canonicalASBDSampleRate:(Float64)sampleRate channel:(UInt32)channel
{
    return CanonicalASBD(sampleRate, channel);
}

- (void)write:(UInt32)inNumberFrames data:(AudioBufferList *)ioData
{
#if TARGET_IPHONE_SIMULATOR
#else   /* TARGET_IPHONE_SIMULATOR */
#endif  /* TARGET_IPHONE_SIMULATOR */
    DBGMSG(@"%s, inNumberFrames(%u), startingSampleCount(%u)", __func__, (unsigned int)inNumberFrames, (unsigned int)self.startingSampleCount);
    uint32_t    available = self.maxSampleCount - self.startingSampleCount;
    if (available < inNumberFrames) {
        inNumberFrames = available;
    }
    memcpy(self.buffer + self.startingSampleCount, ioData->mBuffers[0].mData, sizeof(AudioUnitSampleType) * inNumberFrames);
    self.startingSampleCount = self.startingSampleCount + inNumberFrames;
    if (self.maxSampleCount <= self.startingSampleCount) {
        DBGMSG(@"... stop rec");
        [self stop:nil];
    }
}

@end

static AudioStreamBasicDescription AUCanonicalASBD(Float64 sampleRate, UInt32 channel)
{
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate         = sampleRate;
    audioFormat.mFormatID           = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags        = kAudioFormatFlagsAudioUnitCanonical;
    audioFormat.mChannelsPerFrame   = channel;
    audioFormat.mBytesPerPacket     = sizeof(AudioUnitSampleType);
    audioFormat.mBytesPerFrame      = sizeof(AudioUnitSampleType);
    audioFormat.mFramesPerPacket    = 1;
    audioFormat.mBitsPerChannel     = 8 * sizeof(AudioUnitSampleType);
    audioFormat.mReserved           = 0;
    return audioFormat;
}

static AudioStreamBasicDescription CanonicalASBD(Float64 sampleRate, UInt32 channel)
{
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate         = sampleRate;
    audioFormat.mFormatID           = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags        = kAudioFormatFlagsCanonical;
    audioFormat.mChannelsPerFrame   = channel;
    audioFormat.mBytesPerPacket     = sizeof(AudioSampleType) * channel;
    audioFormat.mBytesPerFrame      = sizeof(AudioSampleType) * channel;
    audioFormat.mFramesPerPacket    = 1;
    audioFormat.mBitsPerChannel     = 8 * sizeof(AudioSampleType);
    audioFormat.mReserved           = 0;
    return audioFormat;
}

static OSStatus MyAURenderCallack(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData)
{
    DBGMSG(@"%s, inNumberFrames:%u", __func__, (unsigned int)inNumberFrames);
    DBGMSG(@"ioData: mNumberBuffers(%u)", (unsigned int)ioData->mNumberBuffers);
    AudioUnitViewController *viewController = (AudioUnitViewController *)inRefCon;
    for (unsigned int i = 0; i < ioData->mNumberBuffers; i++) {
        DBGMSG(@"ioData->mBuffers[%u]: mNumberChannels(%u), mDataByteSize(%u)",
               i,
               (unsigned int)ioData->mBuffers[i].mNumberChannels,
               (unsigned int)ioData->mBuffers[i].mDataByteSize);
    }
    [viewController write:inNumberFrames data:ioData];
    return noErr;
}

/* End Of File */
