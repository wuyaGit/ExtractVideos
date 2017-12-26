//
//  WYPhotoLibraryController.h
//  ExtractVideos
//
//  Created by Yangguangliang on 2017/12/26.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, WYPhotoMediaType) {
    WYPhotoMediaTypeImage   = 0,
    WYPhotoMediaTypeVideo,
    WYPhotoMediaTypeAll
} ;

@interface WYPhotoLibraryController : UINavigationController

@property (nonatomic, assign) WYPhotoMediaType mediaType;

@end

@interface WYPhotoGroup: NSObject

@property (nonatomic, strong) id assetCollection;
@property (nonatomic, strong) id fetchResult;

@property (nonatomic, copy) NSString *groupName;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, copy) void (^getThumbnail)(UIImage *);

- (void)enumerateObjectsUsingBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block;
@end

@interface WYPhoto: NSObject

@property (nonatomic, strong) id asset;


@property (nonatomic, copy) NSString *photoName;
@property (nonatomic, assign) NSInteger photoSize;
@property (nonatomic, strong) UIImage *thumbnail;
@property (nonatomic, copy) void (^getThumbnail)(UIImage *);

@end


@interface WYPhotoGroupViewCell: UITableViewCell

@property (nonatomic, strong) WYPhotoGroup *photoGroup;
@end

@interface WYPhotoGroupViewController: UITableViewController

@end

@interface WYPhotoViewController: UIViewController

@property (nonatomic, strong) WYPhotoGroup *group;
@end
