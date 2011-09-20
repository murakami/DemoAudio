//
//  SystemSoundServicesViewController.h
//  DemoAudio
//
//  Created by 村上 幸雄 on 11/09/20.
//  Copyright 2011年 ビッツ有限会社. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>

@interface SystemSoundServicesViewController : UIViewController {
    SystemSoundID systemSoundID;
}

@property (nonatomic, assign) SystemSoundID systemSoundID;

- (IBAction)play:(id)sender;

@end
