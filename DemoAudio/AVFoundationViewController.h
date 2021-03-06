//
//  AVFoundationViewController.h
//  DemoAudio
//
//  Created by 村上 幸雄 on 11/09/20.
//  Copyright 2011年 ビッツ有限会社. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface AVFoundationViewController : UIViewController <AVAudioPlayerDelegate, AVAudioRecorderDelegate, AVAudioSessionDelegate>

@property (nonatomic, retain) IBOutlet UIButton *recordButton;
@property (nonatomic, retain) IBOutlet UIButton *playButton;
@property (nonatomic, retain) IBOutlet UILabel  *msgLabel;
@property (nonatomic, retain) NSURL             *recordingURL;

- (IBAction)record:(id)sender;
- (IBAction)play:(id)sender;

@end
