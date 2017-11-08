//
//  MainViewController.m
//  SBSAnimoji
//
//  Created by Simon Støvring on 05/11/2017.
//  Copyright © 2017 SimonBS. All rights reserved.
//

#import "MainViewController.h"
#import "MainView.h"
#import "AVTPuppet.h"
#import "AVTPuppetView.h"
#import "PuppetThumbnailCollectionViewCell.h"
#import <objc/runtime.h>

static void *SBSPuppetViewRecordingContext = &SBSPuppetViewRecordingContext;

@interface MainViewController () <SBSPuppetViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, readonly) MainView *contentView;
@property (nonatomic, strong) NSTimer *durationTimer;
@property (nonatomic, strong) NSArray *puppetNames;
@property (nonatomic, assign) BOOL hasExportedMovie;
@end

@implementation MainViewController

// Pragma mark: - Lifecycle

- (instancetype)init {
    if (self = [super init]) {
        self.title = NSLocalizedString(@"Animoke", @"");
        self.puppetNames = [AVTPuppet puppetNames];
    }
    return self;
}

- (void)dealloc {
    [self.contentView.puppetView removeObserver:self forKeyPath:@"recording"];
}

- (MainView *)contentView {
    return (MainView *)self.view;
}

- (void)loadView {
    self.view = [[MainView alloc] init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.contentView.puppetView.sbsDelegate = self;
    self.contentView.thumbnailsCollectionView.dataSource = self;
    self.contentView.thumbnailsCollectionView.delegate = self;
    [self.contentView.thumbnailsCollectionView registerClass:[PuppetThumbnailCollectionViewCell class] forCellWithReuseIdentifier:@"thumbnail"];
    [self.contentView.recordButton addTarget:self action:@selector(toggleRecording) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView.deleteButton addTarget:self action:@selector(removeRecording) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView.previewButton addTarget:self action:@selector(startPreview) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView.shareButton addTarget:self action:@selector(share) forControlEvents:UIControlEventTouchUpInside];
    [self showPuppetNamed:self.puppetNames[0]];
    [self.contentView.thumbnailsCollectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    [self.contentView.puppetView addObserver:self forKeyPath:@"recording" options:NSKeyValueObservingOptionNew context:&SBSPuppetViewRecordingContext];
	
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Music" style:UIBarButtonItemStyleDone target:self action:@selector(chooseMusicSource)];
}

#pragma mark Music Sources
-(void) chooseMusicSource {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Choose Source" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *appleMusic = [UIAlertAction actionWithTitle:@"Apple Music" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self appleMusic];
    }];
    [alertController addAction:appleMusic];

    UIAlertAction *soundCloud = [UIAlertAction actionWithTitle:@"SoundCloud" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self searchSoundCloud];
    }];
    [alertController addAction:soundCloud];

    //YouTube Support Coming Soon
/*
    UIAlertAction *youTube = [UIAlertAction actionWithTitle:@"YouTube" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self searchYouTube];
    }];
    [alertController addAction:youTube];
*/
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {

    }];
    [alertController addAction:cancel];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void) appleMusic {
    MPMediaPickerController *mediaPicker = [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeAnyAudio];
    mediaPicker.delegate = self;
    [mediaPicker setAllowsPickingMultipleItems:NO];
    mediaPicker.showsItemsWithProtectedAssets = NO;
    mediaPicker.showsCloudItems = NO;
    mediaPicker.prompt = NSLocalizedString (@"Add songs to play", "Prompt in media item picker");
    [self presentViewController:mediaPicker animated:YES completion:nil];
}

-(void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
    self.anItem = (MPMediaItem *)[mediaItemCollection.items objectAtIndex:0];
	NSString *lyrics = self.anItem.lyrics;
	if ([lyrics isEqualToString:@""]) {
		self.navigationItem.rightBarButtonItem = nil;
	} else {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Lyrics" style:UIBarButtonItemStyleDone target:self action:@selector(showLyrics)];
	}
	
    if (self.anItem.protectedAsset) {
        NSLog(@"Can't Play This Song");
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Protected Song" message:@"This song is protected and can not be used in this app." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *dismiss = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alertController addAction:dismiss];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        NSURL *assetURL = [self.anItem valueForProperty: MPMediaItemPropertyAssetURL];
        NSLog(@"Picked: %@\n\nPath: %@", mediaItemCollection.items[0].title, assetURL);
        
        [self dismissViewControllerAnimated:YES completion:^{
            AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:assetURL];
            self.songPlayer = [[AVPlayer alloc] initWithPlayerItem:playerItem];
            self.title = mediaItemCollection.items[0].title;
        }];
    }
}

-(void) showLyrics {
	
	if (self.lyricsView.superview !=nil) {
		[UIView animateWithDuration:1.0 delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
			self.lyricsView.frame = CGRectMake(0, 900, self.contentView.bounds.size.width, 212);
		} completion:^(BOOL finished) {
			[self.lyricsView removeFromSuperview];
		}];

	} else {
		self.lyricsView = [[UIView alloc] initWithFrame:CGRectMake(0, 900, self.contentView.bounds.size.width, 212)];
		UITextView *lyricsText = [[UITextView alloc] initWithFrame:self.lyricsView.bounds];
		[lyricsText setText:self.anItem.lyrics];
		lyricsText.textAlignment = NSTextAlignmentCenter;
		lyricsText.font = [UIFont boldSystemFontOfSize:15.0];
		lyricsText.editable = NO;
		[self.lyricsView addSubview:lyricsText];
		[self.contentView addSubview:self.lyricsView];
		[self.contentView bringSubviewToFront:self.lyricsView];
		
		[UIView animateWithDuration:1.0 delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
			self.lyricsView.frame = CGRectMake(0, 600, self.contentView.bounds.size.width, 212);
		} completion:^(BOOL finished) {
			
		}];
	}

}

-(void)searchSoundCloud {
	//Finds Songs on SoundCloud
	SearchViewViewController *searchView = [[SearchViewViewController alloc] init];
	searchView.delegate = self;
	UINavigationController *searchNavigation = [[UINavigationController alloc] initWithRootViewController:searchView];
	searchView.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	[self presentViewController:searchNavigation animated:YES completion:nil];
}

-(void)searchYouTube {
    YouTubeViewController *youTubeController = [[YouTubeViewController alloc] init];
    youTubeController.delegate = self;
    [self.navigationController pushViewController:youTubeController animated:YES];
}

-(void)sendVideoURL:(NSURL *)videoURL {
    NSLog(@"Got YouTube Link: %@", videoURL);
    NSURL *convertYouTube = [NSURL URLWithString:[NSString stringWithFormat:@"www.convertmp3.io/fetch/?video=%@", videoURL]];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:convertYouTube];
    //create the Method "GET"
    [urlRequest setHTTPMethod:@"GET"];
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if(httpResponse.statusCode == 200)
        {
            NSError *parseError = nil;
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
            NSLog(@"The response is - %@",responseDictionary);
        }
        else
        {
            NSLog(@"Error");
        }
    }];
    [dataTask resume];
    
    
}

#pragma mark end Music Sources

-(void)sendDataToA:(AVPlayer *)audioPlayer
{
	NSLog(@"Nah Nah Nah Nah, Yeah... You Are The Music In Me.");
	self.songPlayer = audioPlayer;
}

-(void)setTitleForView:(NSString *)songTitle {
    
    if (songTitle == nil) {
        self.title = @"Animoki";
    } else {
        self.title = songTitle;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"isRecording"] && context == SBSPuppetViewRecordingContext) {
        NSLog(@"%@", self.contentView.puppetView.isRecording ? @"Recording" : @"Not recording");
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (IBAction)mergeAudioInVideo:(NSURL *)videoURL
{
    AVAsset *currentPlayerAsset = self.songPlayer.currentItem.asset;
    NSURL *appleMusicURL = [(AVURLAsset *)currentPlayerAsset URL];
    NSURL *audio_url;
    if (!appleMusicURL) {
        NSString * musicDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
       audio_url = [NSURL fileURLWithPath:[musicDir stringByAppendingString:@"/song_chosen.mp3"]];
    } else {
        audio_url = appleMusicURL;
    }
    
    AVURLAsset  *audioAsset = [[AVURLAsset alloc]initWithURL:audio_url options:nil];
    AVAsset *firstAsset = [AVAsset assetWithURL:videoURL];
    AVAsset *secondAsset = [AVAsset assetWithURL:videoURL];
    
    if(firstAsset !=nil && secondAsset!=nil){
        
        //Create AVMutableComposition Object.This object will hold our multiple AVMutableCompositionTrack.
        AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
        
        //VIDEO TRACK
        AVMutableCompositionTrack *firstTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstAsset.duration) ofTrack:[[firstAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
        
        AVMutableCompositionTrack *secondTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [secondTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondAsset.duration) ofTrack:[[secondAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:firstAsset.duration error:nil];
        
        //AUDIO TRACK
        if(audioAsset!=nil){
            AVMutableCompositionTrack *AudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            [AudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeAdd(firstAsset.duration, secondAsset.duration)) ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:CMTimeMake(1, 10) error:nil];
        }
        
        AVMutableVideoCompositionInstruction * MainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeAdd(firstAsset.duration, secondAsset.duration));
        
        //FIXING ORIENTATION//
        
        AVMutableVideoCompositionLayerInstruction *FirstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
        
        [FirstlayerInstruction setOpacity:0.0 atTime:firstAsset.duration];
        
        MainInstruction.layerInstructions = [NSArray arrayWithObjects:FirstlayerInstruction,nil];;
        
        AVMutableVideoComposition *MainCompositionInst = [AVMutableVideoComposition videoComposition];
        MainCompositionInst.instructions = [NSArray arrayWithObject:MainInstruction];
        
        NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docsDir = [dirPaths objectAtIndex:0];
        NSString *outputFilePath = [docsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"animoji_karaoke.mov"]];
        NSURL *outputFileUrl = [NSURL fileURLWithPath:outputFilePath];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:outputFilePath])
            [[NSFileManager defaultManager] removeItemAtPath:outputFilePath error:nil];
        
        
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
        exporter.outputURL = outputFileUrl;
        exporter.outputFileType = AVFileTypeQuickTimeMovie;
        exporter.timeRange = CMTimeRangeMake(kCMTimeZero,firstAsset.duration);
        [exporter exportAsynchronouslyWithCompletionHandler:^
         {
             dispatch_async(dispatch_get_main_queue(), ^{
                 
                 NSArray *activityItems = @[exporter.outputURL];
                 UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
                 [self presentViewController:activityViewController animated:true completion:nil];
             });
         }];
    }
    
    
}

// Pragma mark: - Private
- (void)share {
    [self exportMovieIfNecessary:^(NSURL *movieURL) {
        if (movieURL == nil) {
            return;
        }
		[self mergeAudioInVideo:movieURL];
    }];
}

- (void)exportMovieIfNecessary:(void(^)(NSURL *))completion {
    NSURL *movieURL = [self movieURL];
    if (self.hasExportedMovie) {
        completion(movieURL);
    } else {
        [self.contentView.activityIndicatorView startAnimating];
        self.contentView.deleteButton.enabled = NO;
        self.contentView.shareButton.hidden = YES;
        __weak typeof(self) weakSelf = self;
        [self.contentView.puppetView exportMovieToURL:movieURL options:nil completionHandler:^{
            weakSelf.hasExportedMovie = YES;
            [weakSelf.contentView.activityIndicatorView stopAnimating];
            weakSelf.contentView.deleteButton.enabled = YES;
            weakSelf.contentView.shareButton.hidden = NO;
            completion(movieURL);
        }];
    }
}

- (void)removeRecording {
    self.hasExportedMovie = NO;
    [self removeExistingMovieFile];
    [self.contentView.puppetView stopRecording];
    [self.contentView.puppetView stopPreviewing];
    self.contentView.recordButton.hidden = NO;
    self.contentView.deleteButton.hidden = YES;
    self.contentView.previewButton.hidden = YES;
    self.contentView.shareButton.hidden = YES;
}

-(void) playSong {
	[self.songPlayer play];
}

- (void)toggleRecording {
    if (self.contentView.puppetView.isRecording) {
		[self.songPlayer pause];
        [self.contentView.puppetView stopRecording];
//		[self mergeAndSave];
    } else {
		[self playSong];
        [self.contentView.puppetView startRecording];
    }
	
}

- (void)durationTimerTriggered {
    int recordingDuration = ceil(self.contentView.puppetView.recordingDuration);
    int minutes = floor(recordingDuration / 60);
    int seconds = recordingDuration % 60;
    NSString *strMinutes;
    NSString *strSeconds;
    if (minutes < 10) {
        strMinutes = [NSString stringWithFormat:@"0%d", minutes];
    } else {
        strMinutes = [NSString stringWithFormat:@"%d", minutes];
    }
    if (seconds < 10) {
        strSeconds = [NSString stringWithFormat:@"0%d", seconds];
    } else {
        strSeconds = [NSString stringWithFormat:@"%d", seconds];
    }
    self.contentView.durationLabel.text = [NSString stringWithFormat:@"%@:%@", strMinutes, strSeconds];
}

- (void)removeExistingMovieFile {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *movieURL = [self movieURL];
    if ([fileManager fileExistsAtPath:movieURL.path]) {
        NSError *error = nil;
        [fileManager removeItemAtURL:movieURL error:&error];
        if (error) {
            NSLog(@"%@", error);
        }
    }
}

- (void)startPreview {
    self.contentView.previewButton.hidden = YES;
    [self.contentView.puppetView stopPreviewing];
    [self.contentView.puppetView startPreviewing];
}

- (NSURL *)movieURL {
    NSURL *documentURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    return [documentURL URLByAppendingPathComponent:@"animoji.mov"];
}

- (void)showPuppetNamed:(NSString *)puppetName {
    AVTPuppet *puppet = [AVTPuppet puppetNamed:puppetName options:nil];
    [self.contentView.puppetView setAvatarInstance:(AVTAvatarInstance *)puppet];
}

// Pragma mark: - SBSPuppetViewDelegate

- (void)puppetViewDidFinishPlaying:(SBSPuppetView *)puppetView {
    if (!puppetView.isRecording) {
        self.contentView.previewButton.hidden = NO;
    }
}

- (void)puppetViewDidStartRecording:(SBSPuppetView *)puppetView {
    self.hasExportedMovie = NO;
    [self removeExistingMovieFile];
    [self.contentView.recordButton setImage:[UIImage imageNamed:@"stop"] forState:UIControlStateNormal];
    self.contentView.durationLabel.text = @"00:00";
    self.contentView.durationLabel.hidden = NO;
    self.durationTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(durationTimerTriggered) userInfo:nil repeats:YES];
    self.contentView.thumbnailsCollectionView.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.3 animations:^{
        self.contentView.thumbnailsCollectionView.alpha = 0.5;
    }];
}

- (void)puppetViewDidStopRecording:(SBSPuppetView *)puppetView {
    [self.durationTimer invalidate];
    self.durationTimer = nil;
    self.contentView.recordButton.hidden = YES;
    self.contentView.shareButton.hidden = NO;
    self.contentView.deleteButton.hidden = NO;
    self.contentView.previewButton.hidden = NO;
    self.contentView.durationLabel.hidden = YES;
    [self.contentView.recordButton setImage:[UIImage imageNamed:@"record"] forState:UIControlStateNormal];
    self.contentView.thumbnailsCollectionView.userInteractionEnabled = YES;
    [UIView animateWithDuration:0.3 animations:^{
        self.contentView.thumbnailsCollectionView.alpha = 1;
    }];
    [self startPreview];
}

// Pragma mark: - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.puppetNames count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    PuppetThumbnailCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"thumbnail" forIndexPath:indexPath];
    NSString *puppetName = self.puppetNames[indexPath.item];
    cell.thumbnailImageView.image = [AVTPuppet thumbnailForPuppetNamed:puppetName options:nil];
    return cell;
}

// Pragma mark: - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *puppetName = self.puppetNames[indexPath.item];
    if (puppetName != nil) {
        [self showPuppetNamed:puppetName];
    }
}

@end
