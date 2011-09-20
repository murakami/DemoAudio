//
//  DemoAudioAppDelegate.h
//  DemoAudio
//
//  Created by 村上 幸雄 on 11/09/20.
//  Copyright 2011年 ビッツ有限会社. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DemoAudioAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate>

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;

@end
