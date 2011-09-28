//
//  AudioUnitViewController.h
//  DemoAudio
//
//  Created by 村上 幸雄 on 11/09/20.
//  Copyright 2011年 ビッツ有限会社. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>

@interface AudioUnitViewController : UIViewController

@property (nonatomic, assign) AUGraph                       auGraph;
@property (nonatomic, assign) AudioStreamBasicDescription   audioUnitOutputFormat;

- (IBAction)record:(id)sender;
- (IBAction)play:(id)sender;
- (IBAction)stop:(id)sender;

@end
