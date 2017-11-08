//
//  YouTubeViewController.h
//  SBSAnimoji
//
//  Created by Sam Gabbay on 11/8/17.
//  Copyright © 2017 SimonBS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@protocol sendYouTubeData <NSObject>

-(void)sendVideoURL:(NSURL *)videoURL; //I am thinking my data is NSArray, you can use another object for store your information.

@end

@interface YouTubeViewController : UIViewController <UIWebViewDelegate, NSURLSessionDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic, assign) id delegate;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) MBProgressHUD *hud;

@end
