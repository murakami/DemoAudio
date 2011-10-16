//
//  AudioQueueServicesViewController.m
//  DemoAudio
//
//  Created by 村上 幸雄 on 11/09/20.
//  Copyright 2011年 ビッツ有限会社. All rights reserved.
//

#import "AudioQueueServicesViewController.h"

static void MyAudioQueueInputCallback(
    void                                *inUserData,
    AudioQueueRef                       inAQ,
    AudioQueueBufferRef                 inBuffer,
    const AudioTimeStamp                *inStartTime,
    UInt32                              inNumberPacketDescriptions,
    const AudioStreamPacketDescription  *inPacketDescs);
static void MyAudioQueueOutputCallback(
    void                 *inUserData,
    AudioQueueRef        inAQ,
    AudioQueueBufferRef  inBuffer);

@interface AudioQueueServicesViewController ()
- (void)prepareBuffer;
- (void)prepareAudioQueueForRecord;
- (void)prepareAudioQueueForPlay;
- (void)readPackets:(AudioQueueBufferRef)inBuffer;
- (void)writePackets:(AudioQueueBufferRef)inBuffer;
@end

@implementation AudioQueueServicesViewController

@synthesize volumeSlider = __volumeSlider;
@synthesize buffer = __buffer;
@synthesize audioQueueObject = __audioQueueObject;
@synthesize numPacketsToRead = __numPacketsToRead;
@synthesize numPacketsToWrite = __numPacketsToWrite;
@synthesize startingPacketCount = __startingPacketCount;
@synthesize maxPacketCount = __maxPacketCount;

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
    free(self.buffer);
    self.volumeSlider = nil;
    self.buffer = NULL;
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
    
    [self prepareBuffer];
    self.audioQueueObject = NULL;
}

- (void)viewDidUnload
{
    DBGMSG(@"%s", __func__);
    self.volumeSlider = nil;
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
    if (self.audioQueueObject)
        return;
    [self prepareAudioQueueForRecord];
    OSStatus    err = AudioQueueStart(self.audioQueueObject, NULL);
    if (err) {
        DBGMSG(@"AudioQueueStart = %d", (int)err);
    }
}

- (IBAction)play:(id)sender
{
    DBGMSG(@"%s", __func__);
    if (self.audioQueueObject)
        return;
    [self prepareAudioQueueForPlay];
    OSStatus    err = AudioQueueStart(self.audioQueueObject, NULL);
    if (err) {
        DBGMSG(@"AudioQueueStart = %d", (int)err);
    }
}

- (IBAction)stop:(id)sender
{
    DBGMSG(@"%s", __func__);
    AudioQueueStop(self.audioQueueObject, YES);
    AudioQueueDispose(self.audioQueueObject, YES);
    self.audioQueueObject = NULL;
}

- (IBAction)volume:(id)sender
{
    if (self.audioQueueObject) {
        AudioQueueParameterValue    volume = self.volumeSlider.value;
        AudioQueueSetParameter(self.audioQueueObject, kAudioQueueParam_Volume, volume);
    }
}

- (void)prepareBuffer
{
    DBGMSG(@"%s", __func__);
    
    UInt32  bytesPerPacket = 2;
    UInt32  sec = 4;
    self.startingPacketCount = 0;
    self.maxPacketCount = (44100 * sec);
    self.buffer = malloc(self.maxPacketCount * bytesPerPacket);
}

- (void)prepareAudioQueueForRecord
{
    DBGMSG(@"%s", __func__);
    
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate         = 44100.0;
    audioFormat.mFormatID           = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags        = kLinearPCMFormatFlagIsSignedInteger
                                    | kLinearPCMFormatFlagIsPacked;
    audioFormat.mFramesPerPacket    = 1;
    audioFormat.mChannelsPerFrame   = 1;
    audioFormat.mBitsPerChannel     = 16;
    audioFormat.mBytesPerPacket     = 2;
    audioFormat.mBytesPerFrame      = 2;
    audioFormat.mReserved           = 0;
    
    AudioQueueNewInput(&audioFormat, MyAudioQueueInputCallback, self, NULL, NULL, 0, &__audioQueueObject);
    
    self.startingPacketCount = 0;
    AudioQueueBufferRef buffers[3];
    
    self.numPacketsToWrite = 1024;
    UInt32  bufferByteSize = self.numPacketsToWrite * audioFormat.mBytesPerPacket;
    
    int bufferIndex;
    for (bufferIndex = 0; bufferIndex < 3; bufferIndex++) {
        AudioQueueAllocateBuffer(self.audioQueueObject, bufferByteSize, &buffers[bufferIndex]);
        AudioQueueEnqueueBuffer(self.audioQueueObject, buffers[bufferIndex], 0, NULL);
    }
}

- (void)prepareAudioQueueForPlay
{
    DBGMSG(@"%s", __func__);

    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate         = 44100.0;
    audioFormat.mFormatID           = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags        = kLinearPCMFormatFlagIsSignedInteger
                                    | kLinearPCMFormatFlagIsPacked;
    audioFormat.mFramesPerPacket    = 1;
    audioFormat.mChannelsPerFrame   = 1;
    audioFormat.mBitsPerChannel     = 16;
    audioFormat.mBytesPerPacket     = 2;
    audioFormat.mBytesPerFrame      = 2;
    audioFormat.mReserved           = 0;
    
    AudioQueueNewOutput(&audioFormat, MyAudioQueueOutputCallback, self, NULL, NULL, 0, &__audioQueueObject);
    
    self.startingPacketCount = 0;
    AudioQueueBufferRef buffers[3];
    
    self.numPacketsToRead = 1024;
    UInt32  bufferByteSize = self.numPacketsToRead * audioFormat.mBytesPerPacket;
    
    int bufferIndex;
    for (bufferIndex = 0; bufferIndex < 3; bufferIndex++) {
        AudioQueueAllocateBuffer(self.audioQueueObject, bufferByteSize, &buffers[bufferIndex]);
        MyAudioQueueOutputCallback(self, self.audioQueueObject, buffers[bufferIndex]);
    }
    
    AudioQueueParameterValue    volume = self.volumeSlider.value;
    AudioQueueSetParameter(self.audioQueueObject, kAudioQueueParam_Volume, volume);
}

- (void)readPackets:(AudioQueueBufferRef)inBuffer
{
    DBGMSG(@"%s", __func__);
    UInt32  bytesPerPacket = 2;
    UInt32  numPackets = self.maxPacketCount - self.startingPacketCount;
    if (self.numPacketsToRead < numPackets) {
        numPackets = self.numPacketsToRead;
    }
    
    if (0 < numPackets) {
        memcpy(inBuffer->mAudioData,
               (self.buffer + (bytesPerPacket * self.startingPacketCount)),
               (bytesPerPacket * numPackets));
        inBuffer->mAudioDataByteSize = (bytesPerPacket * numPackets);
        inBuffer->mPacketDescriptionCount = numPackets;
        self.startingPacketCount += numPackets;
    }
    else {
        inBuffer->mAudioDataByteSize = 0;
        inBuffer->mPacketDescriptionCount = 0;
    }
}

- (void)writePackets:(AudioQueueBufferRef)inBuffer
{
    DBGMSG(@"%s, mAudioDataByteSize(%u), numPackets(%u)",
           __func__,
           (unsigned int)inBuffer->mAudioDataByteSize,
           (unsigned int)(inBuffer->mAudioDataByteSize / 2));
    UInt32  bytesPerPacket = 2;
    UInt32  numPackets = (inBuffer->mAudioDataByteSize / bytesPerPacket);    
    if ((self.maxPacketCount - self.startingPacketCount) < numPackets) {
        numPackets = (self.maxPacketCount - self.startingPacketCount);
    }
    
    if (0 < numPackets) {
        memcpy((self.buffer + (bytesPerPacket * self.startingPacketCount)),
               inBuffer->mAudioData,
               (bytesPerPacket * numPackets));
        self.startingPacketCount += numPackets;
    }
}

@end

static void MyAudioQueueInputCallback(
    void                                *inUserData,
    AudioQueueRef                       inAQ,
    AudioQueueBufferRef                 inBuffer,
    const AudioTimeStamp                *inStartTime,
    UInt32                              inNumberPacketDescriptions,
    const AudioStreamPacketDescription  *inPacketDescs)
{
    DBGMSG(@"%s", __func__);
    AudioQueueServicesViewController    *viewController = (AudioQueueServicesViewController *)inUserData;
    [viewController writePackets:inBuffer];
    AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    
    DBGMSG(@"startingPacketCount(%u), maxPacketCount(%u)",
           (unsigned int)viewController.startingPacketCount,
           (unsigned int)viewController.maxPacketCount);
    if (viewController.maxPacketCount <= viewController.startingPacketCount) {
        [viewController stop:nil];
    }
}

static void MyAudioQueueOutputCallback(
    void                 *inUserData,
    AudioQueueRef        inAQ,
    AudioQueueBufferRef  inBuffer)
{
    DBGMSG(@"%s", __func__);
    AudioQueueServicesViewController    *viewController = (AudioQueueServicesViewController *)inUserData;
    [viewController readPackets:inBuffer];
    AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    
    DBGMSG(@"startingPacketCount(%u), maxPacketCount(%u)",
           (unsigned int)viewController.startingPacketCount,
           (unsigned int)viewController.maxPacketCount);
    if (viewController.maxPacketCount <= viewController.startingPacketCount) {
        viewController.startingPacketCount = 0;
    }
}

/* End Of File */