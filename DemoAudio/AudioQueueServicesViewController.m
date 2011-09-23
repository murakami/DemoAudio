//
//  AudioQueueServicesViewController.m
//  DemoAudio
//
//  Created by 村上 幸雄 on 11/09/20.
//  Copyright 2011年 ビッツ有限会社. All rights reserved.
//

#import "AudioQueueServicesViewController.h"

@interface AudioQueueServicesViewController ()
- (void)readPackets:(AudioQueueBufferRef)inBuffer;
- (void)writePackets:(AudioQueueBufferRef)inBuffer;
@end

@implementation AudioQueueServicesViewController

@synthesize buffer = __buffer;
@synthesize audioQueueObject = __audioQueueObject;
@synthesize audioFileID = __audioFileID;
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
        self.maxPacketCount = (444100 * 4);
        self.buffer = malloc(4 * self.maxPacketCount);
    }
    return self;
}

- (void)dealloc
{
    free(self.buffer);
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
}

- (void)viewDidUnload
{
    DBGMSG(@"%s", __func__);
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)readPackets:(AudioQueueBufferRef)inBuffer
{
    UInt32  numPackets = self.maxPacketCount - self.startingPacketCount;
    if (self.numPacketsToRead < numPackets) {
        numPackets = self.numPacketsToRead;
    }
    
    if (0 < numPackets) {
        memcpy(inBuffer->mAudioData, (self.buffer + (4 * (self.startingPacketCount + numPackets))), (4 * numPackets));
        inBuffer->mAudioDataByteSize = (4 * numPackets);
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
    UInt32  numPackets = inBuffer->mPacketDescriptionCount;
    if ((self.maxPacketCount - self.startingPacketCount) < numPackets) {
        numPackets = (self.maxPacketCount - self.startingPacketCount);
    }
    
    if (0 < numPackets) {
        memcpy((self.buffer + (4 * self.startingPacketCount)), inBuffer->mAudioData, (4 * numPackets));
        self.startingPacketCount += numPackets;
    }
}

@end
