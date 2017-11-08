//
//  SearchViewViewController.m
//  SBSAnimoji
//
//  Created by Sam Gabbay on 11/7/17.
//  Copyright © 2017 SimonBS. All rights reserved.
//

#import "SearchViewViewController.h"

@interface SearchViewViewController ()

@end

@implementation SearchViewViewController

@synthesize delegate;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	self.view.backgroundColor = [UIColor blueColor];
    self.title = @"Search SoundCloud";
	self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
	self.searchController.searchResultsUpdater = self;
	self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.placeholder = @"Search";
	self.searchController.dimsBackgroundDuringPresentation = NO;
	self.navigationItem.searchController = self.searchController;
	
	self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	[self.view addSubview:self.tableView];
	[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissMe)];
}

-(void) dismissMe {
	[self dismissViewControllerAnimated:YES completion:nil];
	[delegate sendDataToA:self.songPlayer];
	[delegate setTitleForView:self.songTitle];

}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.songsArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	SongObject *song = [self.songsArray objectAtIndex:indexPath.row];

	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
	}
	cell.textLabel.text = song.title;
	cell.detailTextLabel.text = song.artist;
	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	SongObject *song = [self.songsArray objectAtIndex:indexPath.row];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.soundcloud.com/tracks/%@/stream?client_id=85652ec093beadb4c647450f597b16ad", song.trackID]];
	AVPlayer *player = [AVPlayer playerWithURL:url];
	self.songTitle = song.title;
	self.songPlayer = player;
	[self downloadSong:song];
}

-(void) downloadSong:(SongObject *)song {
	
	NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.soundcloud.com/tracks/%@/stream?client_id=85652ec093beadb4c647450f597b16ad", song.trackID]];
	NSURLRequest *request = [NSURLRequest requestWithURL:URL];
	NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
	[configuration setSessionSendsLaunchEvents:YES];
	self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
	NSURLSessionDownloadTask *dlTask = [self.session downloadTaskWithRequest:request];
	[dlTask resume];
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
	CGFloat percentDone = (double)totalBytesWritten/(double)totalBytesExpectedToWrite;
	dispatch_async(dispatch_get_main_queue(), ^{
		//Update the progress view
		float progressFloat = percentDone*100;
		NSLog(@"Download: %f", progressFloat);
	});
	// Notify user.
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
	// Either move the data from the location to a permanent location, or do something with the data at that location.
	//	let fileSize = try! NSFileManager.defaultManager().attributesOfItemAtPath(fileURL.path!)[NSFileSize]!.longLongValue
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
		[self dismissMe];
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



#pragma mark SearchView Delegate

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
	NSLog(@"Query: %@", searchController.searchBar.text);
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	NSLog(@"Query: %@", searchBar.text);
	[self searchSoundCloud:searchBar.text];
}

#pragma mark Network Calls

-(void) searchSoundCloud:(NSString *)query {
	[self setTitle:@"Searching..."];
	NSString *newQuery = [query stringByReplacingOccurrencesOfString:@" " withString:@"+"];
	NSString *queryURLString = [NSString stringWithFormat:@"https://api.soundcloud.com/tracks.json?q=%@&client_id=85652ec093beadb4c647450f597b16ad&limit=50", newQuery];
	
	NSCharacterSet *set = [NSCharacterSet URLQueryAllowedCharacterSet];
	NSString *encodedUrlAsString = [queryURLString stringByAddingPercentEncodingWithAllowedCharacters:set];
	
	NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
	__block int j = 0;
	
	[[session dataTaskWithURL:[NSURL URLWithString:encodedUrlAsString]
			completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
				
				if (!error) {
					// Success
					if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
						NSError *jsonError;
						NSArray *songs = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
						
						if (jsonError) {
							// Error Parsing JSON
							NSLog(@"JSON Error: %@", jsonError);
						} else {
							// Success Parsing JSON
							// Log NSDictionary response:
							self.songsArray = [NSMutableArray new];
							for (NSDictionary *productDictionary in songs) {
								j++;
								SongObject *song = [[SongObject alloc] initWithDictionary:productDictionary];
								[self.songsArray addObject:song];
								
								if (j == songs.count) {
									dispatch_async(dispatch_get_main_queue(), ^{
										[self setTitle:query];
										[self.tableView reloadData];
									});
									
								} else {
								}
								
							}
						}
					}  else {
						//Web server is returning an error
					}
				} else {
					// Fail
					NSLog(@"error : %@", error.description);
				}
			}] resume];
	
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
