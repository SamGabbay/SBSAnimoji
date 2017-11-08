//
//  SongObject.m
//  SoundCloud WatchKit Extension
//
//  Created by Sam Gabbay on 9/26/17.
//  Copyright © 2017 Sam Gabbay. All rights reserved.
//

#import "SongObject.h"

@implementation SongObject

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        self.title = dictionary[@"title"];
		self.playback_count = [dictionary[@"playback_count"] intValue];
		
		if (dictionary[@"likes_count"] == nil) {
			self.likesCount = [dictionary[@"favoritings_count"] intValue];
		} else {
			self.likesCount = [dictionary[@"likes_count"] intValue];
		}
		
        self.artist = [[dictionary objectForKey:@"user"] objectForKey:@"username"];
        self.duration = dictionary[@"duration"];
        self.trackID = dictionary[@"id"];
        NSString *artworkString = dictionary[@"artwork_url"];
        if (artworkString == nil || [artworkString isEqual:[NSNull null]]) {
            self.artworkURL = [[dictionary objectForKey:@"user"] objectForKey:@"avatar_url"];
        } else {
			artworkString = [artworkString stringByReplacingOccurrencesOfString:@"-large" withString:@"-t500x500"];
            self.artworkURL = artworkString;
        }
        
    }
    return self;
}

- (id)initWithArray:(NSArray *)array {
	self = [super init];
	
	if (self) {
		self.trackID = [self getFileInfoWithArray:array withExtension:@"mp3"];
		self.title = [self getFileInfoWithArray:array withExtension:@"txt"];
		NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
		NSString *txtFile = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@/%@.txt", self.trackID, self.title]];
		NSString *content = [[NSString alloc] initWithContentsOfFile:txtFile encoding:NSUTF8StringEncoding error:nil];
		self.artist = [content componentsSeparatedByString:@"\n\n"][1];
		NSString *imgFile = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@/%@.png", self.trackID, self.trackID]];
		self.artworkData = [NSData dataWithContentsOfFile:imgFile];
		self.songPath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@/%@.mp3", self.trackID, self.trackID]];

	}
	return self;
}

-(NSString *)getFileInfoWithArray:(NSArray *)array withExtension:(NSString *)extension {
	NSString *file = [array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:[NSString stringWithFormat:@"self ENDSWITH '.%@'", extension]]][0];
	NSArray *clip = [file componentsSeparatedByString:[NSString stringWithFormat:@".%@", extension]];
	NSString *finalFile = clip[0];
	return finalFile;
}

@end
