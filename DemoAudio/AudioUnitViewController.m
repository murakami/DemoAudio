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
static OSStatus MyPlayAURenderCallack (
                                   void                        *inRefCon,
                                   AudioUnitRenderActionFlags  *ioActionFlags,
                                   const AudioTimeStamp        *inTimeStamp,
                                   UInt32                      inBusNumber,
                                   UInt32                      inNumberFrames,
                                   AudioBufferList             *ioData
                                   );


@interface AudioUnitViewController ()
- (void)prepareBuffer;
- (void)prepareAUGraph;
- (void)prepareAudioUnit;
- (AudioStreamBasicDescription)auCanonicalASBDSampleRate:(Float64)sampleRate channel:(UInt32)channel;
- (AudioStreamBasicDescription)canonicalASBDSampleRate:(Float64)sampleRate channel:(UInt32)channel;
- (void)write:(UInt32)inNumberFrames data:(AudioBufferList *)ioData;
- (void)read:(UInt32)inNumberFrames data:(AudioBufferList *)ioData;
@end

@implementation AudioUnitViewController

@synthesize auGraph = __auGraph;
@synthesize isRecording = __isRecording;
@synthesize audioUnit = __audioUnit;
@synthesize phase = __phase;
@synthesize sampleRate = __sampleRate;
@synthesize isPlaying = __isPlaying;
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
    self.isPlaying = NO;
    [self prepareAUGraph];
    [self prepareAudioUnit];
}

- (void)viewDidUnload
{
    DBGMSG(@"%s", __func__);
    
    if (self.isRecording)   [self stop:nil];
    AUGraphUninitialize(self.auGraph);
    AUGraphClose(self.auGraph);
    DisposeAUGraph(self.auGraph);
    
    if (self.isPlaying) [self stop:nil];
    AudioUnitUninitialize(self.audioUnit);
    AudioComponentInstanceDispose(self.audioUnit);
    
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
    
    AUGraphStart(self.auGraph);
    AUGraphAddRenderNotify(self.auGraph, MyAURenderCallack, self);
    self.isRecording = YES;
    self.startingSampleCount = 0;
}

- (IBAction)play:(id)sender
{
    DBGMSG(@"%s", __func__);
    if (self.isPlaying) return;
    
    AudioOutputUnitStart(self.audioUnit);
    self.isPlaying = YES;
    self.startingSampleCount = 0;
}

- (IBAction)stop:(id)sender
{
    DBGMSG(@"%s", __func__);    
    if (self.isRecording) {
        AUGraphRemoveRenderNotify(self.auGraph, MyAURenderCallack, self);
        AUGraphStop(self.auGraph);
    }
    if (self.isPlaying) {
        AudioOutputUnitStop(self.audioUnit);
    }
    self.isRecording = NO;
    self.isPlaying = NO;
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

- (void)prepareAudioUnit
{
    DBGMSG(@"%s", __func__);

    AudioComponentDescription   cd;
    cd.componentType            = kAudioUnitType_Output;
    cd.componentSubType         = kAudioUnitSubType_RemoteIO;
    cd.componentManufacturer    = kAudioUnitManufacturer_Apple;
    cd.componentFlags           = 0;
    cd.componentFlagsMask       = 0;

    AudioComponent  component = AudioComponentFindNext(NULL, &cd);
    AudioComponentInstanceNew(component, &__audioUnit);
    AudioUnitInitialize(self.audioUnit);
    AURenderCallbackStruct  callbackStruct;
    callbackStruct.inputProc = MyPlayAURenderCallack;
    callbackStruct.inputProcRefCon = self;
    AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &callbackStruct, sizeof(AURenderCallbackStruct));

    self.phase = 0.0;
    self.sampleRate = 44100.0;
    
    AudioStreamBasicDescription audioFormat = [self auCanonicalASBDSampleRate:self.sampleRate channel:2];
    
    AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &audioFormat, sizeof(AudioStreamBasicDescription));
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

- (void)read:(UInt32)inNumberFrames data:(AudioBufferList *)ioData
{
#if TARGET_IPHONE_SIMULATOR
#else   /* TARGET_IPHONE_SIMULATOR */
#endif  /* TARGET_IPHONE_SIMULATOR */
    DBGMSG(@"%s, inNumberFrames(%u), startingSampleCount(%u)", __func__, (unsigned int)inNumberFrames, (unsigned int)self.startingSampleCount);
    uint32_t    available = self.maxSampleCount - self.startingSampleCount;
    uint32_t    num = inNumberFrames;
    if (available < num) {
        num = available;
    }
    memcpy(ioData->mBuffers[0].mData, self.buffer + self.startingSampleCount, num);
    self.startingSampleCount = self.startingSampleCount + num;
    if (self.maxSampleCount <= self.startingSampleCount)
        self.startingSampleCount = 0;
    if (num < inNumberFrames) {
        num = inNumberFrames - num;
        memcpy(ioData->mBuffers[0].mData, self.buffer + self.startingSampleCount, num);
        self.startingSampleCount = self.startingSampleCount + num;
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
    DBGMSG(@"%s, inBusNumber:%u, inNumberFrames:%u", __func__, (unsigned int)inBusNumber, (unsigned int)inNumberFrames);
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

static OSStatus MyPlayAURenderCallack (
                                       void                        *inRefCon,
                                       AudioUnitRenderActionFlags  *ioActionFlags,
                                       const AudioTimeStamp        *inTimeStamp,
                                       UInt32                      inBusNumber,
                                       UInt32                      inNumberFrames,
                                       AudioBufferList             *ioData
                                       )
{
    DBGMSG(@"%s, inBusNumber:%u, inNumberFrames:%u", __func__, (unsigned int)inBusNumber, (unsigned int)inNumberFrames);
    DBGMSG(@"ioData: mNumberBuffers(%u)", (unsigned int)ioData->mNumberBuffers);
    AudioUnitViewController *viewController = (AudioUnitViewController *)inRefCon;
    for (unsigned int i = 0; i < ioData->mNumberBuffers; i++) {
        DBGMSG(@"ioData->mBuffers[%u]: mNumberChannels(%u), mDataByteSize(%u)",
               i,
               (unsigned int)ioData->mBuffers[i].mNumberChannels,
               (unsigned int)ioData->mBuffers[i].mDataByteSize);
    }
    /*
    [viewController read:inNumberFrames data:ioData];
    */
    
    float   freq = 440 * 2.0 * M_PI / viewController.sampleRate;
    double  phase = viewController.phase;
    AudioUnitSampleType *outL = ioData->mBuffers[0].mData;
    AudioUnitSampleType *outR = ioData->mBuffers[1].mData;
    for (int i = 0; i < inNumberFrames; i++) {
        float   wave = sin(phase);
        AudioUnitSampleType sample = wave * (1 << kAudioUnitSampleFractionBits);
        *outL++ = sample;
        *outR++ = sample;
        phase = phase + freq;
    }
    viewController.phase = phase;
    return noErr;
}

/* End Of File */
