//
//  SongObject.h
//  SoundCloud WatchKit Extension
//
//  Created by Sam Gabbay on 9/26/17.
//  Copyright © 2017 Sam Gabbay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

@interface SongObject : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *artist;
@property (nonatomic, strong) NSString *duration;
@property (nonatomic, strong) NSString *trackID;
@property (nonatomic, strong) NSString *artworkURL;
@property (nonatomic) int likesCount;
@property (nonatomic) int playback_count;

@property (nonatomic, strong) NSData *artworkData;
//@property (nonatomic, strong) WKAudioFileAsset *asset;
@property (nonatomic, strong) NSString *songPath;

- (id)initWithDictionary:(NSDictionary *)dictionary;
- (id)initWithArray:(NSArray *)array;
@end
