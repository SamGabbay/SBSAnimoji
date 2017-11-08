//
//  SearchViewViewController.h
//  SBSAnimoji
//
//  Created by Sam Gabbay on 11/7/17.
//  Copyright © 2017 SimonBS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SongObject.h"
#import "MainViewController.h"
#import "MBProgressHUD.h"

@protocol senddataProtocol <NSObject>

-(void)sendDataToA:(AVPlayer *)audioPlayer; //I am thinking my data is NSArray, you can use another object for store your information.
-(void)setTitleForView:(NSString *)songTitle;

@end

@interface SearchViewViewController : UIViewController <UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, NSURLSessionDelegate, NSURLSessionDownloadDelegate>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UISearchController *searchController;
@property (nonatomic, strong) NSMutableArray *songsArray;
@property (nonatomic, assign) id delegate;
@property (nonatomic, strong) AVPlayer *songPlayer;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSString *songTitle;
@property (nonatomic, strong) MBProgressHUD *hud;

@end
