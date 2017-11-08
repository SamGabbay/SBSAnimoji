//
//  MainViewController.h
//  SBSAnimoji
//
//  Created by Simon Støvring on 05/11/2017.
//  Copyright © 2017 SimonBS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <SafariServices/SafariServices.h>
#import "AppDelegate.h"

@interface MainViewController : UIViewController <MPMediaPickerControllerDelegate, SFSafariViewControllerDelegate>

@property (nonatomic, strong) AVPlayer *songPlayer;
@property (nonatomic, strong) NSURL *songPath;
@property (nonatomic, strong) MPMediaItem *anItem;
@property (nonatomic, strong) UIView *lyricsView;
@property (nonatomic, strong) SFSafariViewController *safariController;


@end

