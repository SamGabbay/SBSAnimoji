//
//  YouTubeViewController.m
//  SBSAnimoji
//
//  Created by Sam Gabbay on 11/8/17.
//  Copyright © 2017 SimonBS. All rights reserved.
//

#import "YouTubeViewController.h"

@interface YouTubeViewController ()

@end

@implementation YouTubeViewController

@synthesize delegate;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://youtube.com"]];
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    [webView loadRequest:request];
    [webView setDelegate:self];
    [webView setMediaPlaybackRequiresUserAction:YES];
    [webView setAllowsInlineMediaPlayback:false];
    [self.view addSubview:webView];
}

-(void)webViewDidStartLoad:(UIWebView *)webView {
    if ([[webView.request.URL absoluteString] containsString:@"/watch?v="]) {
        [self downloadSong:webView.request.URL];
    } else {
        NSLog(@"didStartLoad: %@", webView.request.URL);
    }
}

-(void) downloadSong:(NSURL *)videoURL {
    NSString *replaceMobileLink = [[videoURL absoluteString] stringByReplacingOccurrencesOfString:@"//m." withString:@"//"];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.convertmp3.io/fetch/?video=%@", replaceMobileLink]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    [configuration setSessionSendsLaunchEvents:YES];
    self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    NSURLSessionDownloadTask *dlTask = [self.session downloadTaskWithRequest:request];
    [dlTask resume];
    
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];

}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    CGFloat percentDone = (double)totalBytesWritten/(double)totalBytesExpectedToWrite;
    dispatch_async(dispatch_get_main_queue(), ^{
        //Update the progress view
        float progressFloat = percentDone*100;
        self.hud.mode = MBProgressHUDModeAnnularDeterminate;
        self.hud.label.text = @"Downloading";
        self.hud.progress = progressFloat;
        NSLog(@"Download: %f", progressFloat);
    });
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    [self.hud hideAnimated:YES];
    // Either move the data from the location to a permanent location, or do something with the data at that location.
    //    let fileSize = try! NSFileManager.defaultManager().attributesOfItemAtPath(fileURL.path!)[NSFileSize]!.longLongValue
    [self removeSong:@"song_chosen.mp3"];
    NSError *attributesError;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[location path] error:&attributesError];
    
    NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
    long long fileSize = [fileSizeNumber longLongValue];
    NSLog(@"Done Downloading: %@\n\nSize: %lld", location, fileSize);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    
    //getting application's document directory path
    NSString * docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    docsDir = [docsDir stringByAppendingString:@"/song_chosen.mp3"];
    
    //retrieving the filename from the response and appending it again to the path
    //this path "appDir" will be used as the target path
    //moving the file from temp location to app's own directory
    BOOL fileCopied = [fileManager moveItemAtPath:[location path] toPath:docsDir error:&error];
    NSLog(fileCopied ? @"Yes" : @"No");
    NSString *finalPath = [NSString stringWithFormat:@"file://%@", docsDir];
    NSLog(@"Final Destination 2: %@", finalPath);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController popViewControllerAnimated:YES];
    });
    
}

- (void)removeSong:(NSString *)filename
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *filePath = [documentsPath stringByAppendingPathComponent:filename];
    NSError *error;
    BOOL success = [fileManager removeItemAtPath:filePath error:&error];
    if (success) {
        NSLog(@"Deleted");
    }
    else
    {
        NSLog(@"Could not delete file -:%@ ",[error localizedDescription]);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
