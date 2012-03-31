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
- (void)prepareAUGraph;
- (AudioStreamBasicDescription)auCanonicalASBDSampleRate:(Float64)sampleRate channel:(UInt32)channel;
- (AudioStreamBasicDescription)canonicalASBDSampleRate:(Float64)sampleRate channel:(UInt32)channel;
@end

@implementation AudioUnitViewController

@synthesize auGraph = __auGraph;
@synthesize isRecording = __isRecording;
@synthesize audioUnitOutputFormat = __audioUnitOutputFormat;

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

    self.isRecording = NO;
    [self prepareAUGraph];
}

- (void)viewDidUnload
{
    DBGMSG(@"%s", __func__);
    
    if (self.isRecording)   [self stop:nil];
    AUGraphUninitialize(self.auGraph);
    AUGraphClose(self.auGraph);
    DisposeAUGraph(self.auGraph);
    
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
    
    AUGraphStart(self.auGraph);
    AUGraphAddRenderNotify(self.auGraph, MyAURenderCallack, NULL);
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

    AUGraphRemoveRenderNotify(self.auGraph, MyAURenderCallack, NULL);
    AUGraphStop(self.auGraph);
    self.isRecording = NO;
}

- (void)prepareAUGraph
{
    DBGMSG(@"%s", __func__);
    AUNode      remoteIONode;
    AudioUnit   remoteIOUnit;
    
    NewAUGraph(&__auGraph);
    AUGraphOpen(self.auGraph);
    
    AudioComponentDescription   cd;
    cd.componentType            = kAudioUnitType_Output;
    cd.componentSubType         = kAudioUnitSubType_RemoteIO;
    cd.componentManufacturer    = kAudioUnitManufacturer_Apple;
    cd.componentFlags           = 0;
    cd.componentFlagsMask       = 0;
    
    AUGraphAddNode(self.auGraph, &cd, &remoteIONode);
    AUGraphNodeInfo(self.auGraph, remoteIONode, NULL, &remoteIOUnit);
    
    UInt32  flag = 1;
    AudioUnitSetProperty(remoteIOUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &flag, sizeof(flag));
    
    AudioStreamBasicDescription audioFormat = [self canonicalASBDSampleRate:44100.0 channel:1];
    AudioUnitSetProperty(remoteIOUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &audioFormat, sizeof(AudioStreamBasicDescription));
    AudioUnitSetProperty(remoteIOUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &audioFormat, sizeof(AudioStreamBasicDescription));
    
    //AUGraphConnectNodeInput(self.auGraph, remoteIONode, 1, remoteIONode, 0);
    AUGraphInitialize(self.auGraph);
}

- (AudioStreamBasicDescription)auCanonicalASBDSampleRate:(Float64)sampleRate channel:(UInt32)channel
{
    return AUCanonicalASBD(sampleRate, channel);
}

- (AudioStreamBasicDescription)canonicalASBDSampleRate:(Float64)sampleRate channel:(UInt32)channel
{
    return CanonicalASBD(sampleRate, channel);
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
    for (unsigned int i = 0; i < ioData->mNumberBuffers; i++) {
        DBGMSG(@"ioData->mBuffers[%u]: mNumberChannels(%u), mDataByteSize(%u)",
               i,
               (unsigned int)ioData->mBuffers[i].mNumberChannels,
               (unsigned int)ioData->mBuffers[i].mDataByteSize);
    }
    return noErr;
}

/* End Of File */
