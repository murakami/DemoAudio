//
//  AudioQueueServicesViewController.h
//  DemoAudio
//
//  Created by 村上 幸雄 on 11/09/20.
//  Copyright 2011年 ビッツ有限会社. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

@interface AudioQueueServicesViewController : UIViewController

@property (nonatomic, assign) char          *buffer;
@property (nonatomic, assign) AudioQueueRef audioQueueObject;
@property (nonatomic, assign) AudioFileID   audioFileID;
@property (nonatomic, assign) UInt32        numPacketsToRead;
@property (nonatomic, assign) UInt32        numPacketsToWrite;
@property (nonatomic, assign) SInt64        startingPacketCount;
@property (nonatomic, assign) SInt64        maxPacketCount;

@end
