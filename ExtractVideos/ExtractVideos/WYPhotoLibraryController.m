//
//  WYPhotoLibraryController.m
//  ExtractVideos
//
//  Created by Yangguangliang on 2017/12/26.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import "WYPhotoLibraryController.h"
#import <Photos/Photos.h>

#define kThumbImageHeight    80.0f
#define kThumbImageSize      CGSizeMake(kThumbImageHeight, kThumbImageHeight)


@implementation WYPhotoLibraryController

- (instancetype)init {
    WYPhotoGroupViewController *rootViewController = [[WYPhotoGroupViewController alloc] init];
    if (self = [super initWithRootViewController:rootViewController]) {
        
    }
    
    return self;
}

@end

@interface WYPhotoGroup()

@property (nonatomic, strong) UIImage *cacheThumbImage;
@end

@implementation WYPhotoGroup

- (void)setGetThumbnail:(void (^)(UIImage *))getThumbnail {
    _getThumbnail = getThumbnail;
    
    if (_cacheThumbImage) {
        _getThumbnail(_cacheThumbImage);
        return;
    }
    
    if ([_assetCollection isKindOfClass:[PHCollection class]]) {
        if (!_fetchResult) {
            PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
            _fetchResult = [PHCollection fetchCollectionsInCollectionList:_assetCollection options:fetchOptions];
        }
        
        PHFetchResult *tmpFetchResult = _fetchResult;
        PHAsset *tmpAsset = [tmpFetchResult objectAtIndex:tmpFetchResult.count - 1];
        
        PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
        requestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
        [[PHImageManager defaultManager] requestImageForAsset:tmpAsset targetSize:CGSizeMake(200, 200) contentMode:PHImageContentModeAspectFill options:requestOptions resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            BOOL download = ![info[PHImageCancelledKey] boolValue] && ![info[PHImageErrorKey] boolValue] && ![info[PHImageResultIsDegradedKey] boolValue];
            
            if (download) {
                float scale = result.size.height / kThumbImageHeight;
                _cacheThumbImage = [UIImage imageWithCGImage:result.CGImage scale:scale orientation:UIImageOrientationUp];
                _getThumbnail(_cacheThumbImage);
            }
            
        }];
    }
}

- (void)enumerateObjectsUsingBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block {
    if (_assetCollection) {
        if ([_assetCollection isKindOfClass:[PHCollection class]]) {
            if (!_fetchResult) {
                PHFetchOptions *tmpFetchOptions = [[PHFetchOptions alloc] init];
                _fetchResult = [PHCollection fetchCollectionsInCollectionList:_assetCollection options:tmpFetchOptions];
            }
            [(PHFetchResult *) _fetchResult enumerateObjectsUsingBlock:block];
        }
    }
}

@end

@implementation WYPhotoGroupViewCell

- (void)setPhotoGroup:(WYPhotoGroup *)photoGroup {
    _photoGroup = photoGroup;
    
    __weak typeof(self) weakSelf = self;
    [_photoGroup setGetThumbnail:^(UIImage *image) {
        weakSelf.imageView.image = image;
        [weakSelf setNeedsLayout];
    }];
    
    self.textLabel.text = photoGroup.groupName;
    self.detailTextLabel.text = [NSString stringWithFormat:@"%zi", photoGroup.count];
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

@end

@interface WYPhotoGroupViewController ()

@property (nonatomic, strong) NSMutableArray *photoGroups;
@end

@implementation WYPhotoGroupViewController

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.photoGroups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    WYPhotoGroupViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[WYPhotoGroupViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    cell.photoGroup = self.photoGroups[indexPath.row];
    
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kThumbImageHeight + 10;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    WYPhotoViewController *viewController = [[WYPhotoViewController alloc] init];
    viewController.group = self.photoGroups[indexPath.row];
    
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - Cycle life

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupView];
    [self setupBarButtonItem];
    [self setupGroup];
}

#pragma mark - Setup

- (void)setupView {
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)setupBarButtonItem {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(dismiss:)];
}

- (void)setupGroup {
    if (self.photoGroups) {
        [self.photoGroups removeAllObjects];
    }else {
        self.photoGroups = [[NSMutableArray alloc] init];
    }
    
    __block BOOL showAlbums = YES;
    WYPhotoLibraryController *library = (WYPhotoLibraryController *)self.navigationController;
    
    //iOS8以后,使用PHAsset
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    
    //获取所有系统相册
    PHFetchResult *smartAlbumsFetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:fetchOptions];
    //遍历相册
    [smartAlbumsFetchResult enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
        showAlbums = NO;
        PHFetchOptions *fetchOptionsAlbums = [[PHFetchOptions alloc] init];
        
        switch (library.mediaType) {
            case WYPhotoMediaTypeImage:
                fetchOptionsAlbums.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
                break;
            case WYPhotoMediaTypeVideo:
                fetchOptionsAlbums.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeVideo];
                break;
            default:
                break;
        }
        
        //有可能是PHCollectionList，会造成crash，过滤掉
        if ([collection isKindOfClass:[PHAssetCollection class]]) {
            //从相册中获取数据
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:fetchOptionsAlbums];
            //去掉视频和最近删除的
            if (![collection.localizedTitle isEqualToString:@"Videos"]) {
                if (fetchResult.count > 0) {
                    WYPhotoGroup *group = [[WYPhotoGroup alloc] init];
                    group.groupName = collection.localizedTitle;
                    group.count = fetchResult.count;
                    group.assetCollection = collection;
                    group.fetchResult = fetchResult;
                    [self.photoGroups addObject:group];
                }
            }
        }
    }];
    
    //获取所有自定义相册
    PHFetchResult *userAlbumsFetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:fetchOptions];
    //遍历相册
    [userAlbumsFetchResult enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
        showAlbums = NO;
        PHFetchOptions *fetchOptionsAlbums = [[PHFetchOptions alloc] init];
        
        switch (library.mediaType) {
            case WYPhotoMediaTypeImage:
                fetchOptionsAlbums.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
                break;
            case WYPhotoMediaTypeVideo:
                fetchOptionsAlbums.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeVideo];
                break;
            default:
                break;
        }
        
        PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:fetchOptionsAlbums];
        if (fetchResult.count > 0) {
            WYPhotoGroup *group = [[WYPhotoGroup alloc] init];
            group.groupName = collection.localizedTitle;
            group.count = fetchResult.count;
            group.assetCollection = collection;
            group.fetchResult = fetchResult;
            [self.photoGroups addObject:group];
        }
    }];

    if (showAlbums) {
        [self noAllowed];
    }else {
        [self reloadData];
    }
}

#pragma mark - No allowed OR NO Asset

- (void)noAllowed {
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    NSString *tipTextWhenNoPhotosAuthorization = [NSString stringWithFormat:@"请在设备的\"设置-隐私-照片\"选项中，允许%@访问您的手机相册。", appName];

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"此应用没有权限访问相册" message:tipTextWhenNoPhotosAuthorization preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *qdAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:qdAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)noAssets {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"没有照片或视频" message:@"您可以使用 iTunes 将照片和视频\n同步到 iPhone。" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *qdAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:qdAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Action

- (void)dismiss:(id)sender {
    WYPhotoLibraryController *picker = (WYPhotoLibraryController *)self.navigationController;
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)reloadData {
    if (self.photoGroups.count == 0) {
        [self noAssets];
    }
    
    [self.tableView reloadData];
}

@end

@interface WYCollectionViewCell: UICollectionViewCell

@property (nonatomic, strong) WYPhoto *photo;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UILabel *fileSizeLabel;

@end

@implementation WYCollectionViewCell

- (void)setPhoto:(WYPhoto *)photo {
    _photo = photo;
    
    __weak typeof(self) weakSelf = self;
    [_photo setGetThumbnail:^(UIImage *image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.imageView.image = image;
        });
    }];
    
    
}

- (UIImageView *)imageView {
    if (_imageView == nil) {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.clipsToBounds = YES;
        [self.contentView addSubview:imageView];
        _imageView = imageView;
    }
    
    return _imageView;
}

- (UIView *)bottomView {
    if (_bottomView == nil) {
        UIView *bottomView = [[UIView alloc] init];
        bottomView.frame = CGRectMake(0, self.frame.size.height - 17, self.frame.size.width, 17);
        bottomView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
        [self.contentView addSubview:bottomView];
        _bottomView = bottomView;
    }
    return _bottomView;
}

- (UILabel *)fileSizeLabel {
    if (_fileSizeLabel) {
        UILabel *fileSizeLabel = [[UILabel alloc] init];
        fileSizeLabel.font = [UIFont boldSystemFontOfSize:11];
        fileSizeLabel.frame = CGRectMake(0, 0, self.frame.size.width - 5, 17);
        fileSizeLabel.textColor = [UIColor whiteColor];
        fileSizeLabel.textAlignment = NSTextAlignmentRight;
        [self.bottomView addSubview:fileSizeLabel];
        _fileSizeLabel = fileSizeLabel;

    }
    return _fileSizeLabel;
}


- (UIButton *)deleteButton {
    if (_deleteButton == nil) {
        _deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
        [_deleteButton setImage:[UIImage imageNamed:@"del_red_icon"] forState:UIControlStateNormal];
//        [_deleteButton addTarget:self action:@selector(onTouchDeleteAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _deleteButton;
}

//- (void)subView:(NSString *)imgUrl {
//    if (_imgView == nil) {
//        self.imgView.translatesAutoresizingMaskIntoConstraints = NO;
//        [self addSubview:self.imgView];
//
//        NSDictionary *views = @{@"imgView": self.imgView};
//        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-4-[imgView]-4-|" options:0 metrics:nil views:views]];
//        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-4-[imgView]-4-|" options:0 metrics:nil views:views]];
//    }
//
////    [self.imgView sd_setImageWithURL:[NSURL URLWithString:imgUrl] placeholderImage:[UIImage imageNamed:@"default_peixun"]];
//
//    if (_deleteButton == nil) {
//        [self addSubview:self.deleteButton];
//
////        self.deleteButton.frame = CGRectMake(self.width - 28, _imgView.originY - 1, 22, 22);
//    }
//}

@end

@interface WYCollectionHeaderReusableView : UICollectionReusableView

@end

@implementation WYCollectionHeaderReusableView

@end

@interface WYCollectionFooterReusableView : UICollectionReusableView

@end

@implementation WYCollectionFooterReusableView

@end

@interface WYPhoto()

@property (nonatomic, strong) UIImage *cacheThumbImage;
@end

@implementation WYPhoto

- (void)setGetThumbnail:(void (^)(UIImage *))getThumbnail {
    _getThumbnail = getThumbnail;
    
    if (_asset) {
        if (_cacheThumbImage) {
            _getThumbnail(_cacheThumbImage);
            return;
        }
        
        if ([_asset isKindOfClass:[PHAsset class]]) {
            PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
            requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
            requestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
            [[PHImageManager defaultManager] requestImageForAsset:_asset targetSize:CGSizeMake(200, 200) contentMode:PHImageContentModeAspectFill options:requestOptions resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                BOOL download = ![info[PHImageCancelledKey] boolValue] && ![info[PHImageErrorKey] boolValue] && ![info[PHImageResultIsDegradedKey] boolValue];
                
                if (download) {
                    _cacheThumbImage = result;
                    _getThumbnail(_cacheThumbImage);
                }
            }];
        }
        
    }
}

@end

@interface WYPhotoViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *photos;

@end

@implementation WYPhotoViewController

#pragma mark - Collection view data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.photos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WYCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.photo = self.photos[indexPath.item];
        
    return cell;
}

/** 头部/底部*/
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        // 头部
        WYCollectionHeaderReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"header" forIndexPath:indexPath];
        view.backgroundColor = [UIColor orangeColor];
        
        return view;
    }else {
        // 底部
        WYCollectionFooterReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"footer" forIndexPath:indexPath];
        view.backgroundColor = [UIColor blueColor];
        
        return view;
    }
}

#pragma mark - Collection view delegate flowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.view.frame.size.width / 4 - 5, self.view.frame.size.width / 4 - 5);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(self.view.frame.size.width, 1);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(self.view.frame.size.width, 1);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(10, 3, 10, 3);
}

#pragma mark - Collection view delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

}

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupView];
    [self setupBarButtonItem];
    [self setupData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup

- (void)setupView {
    [self.view addSubview:self.collectionView];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSDictionary *views = @{@"collectionView": self.collectionView};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-15-[collectionView]-61-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[collectionView]|" options:0 metrics:nil views:views]];
    
    // 注册collectionViewcell:WWCollectionViewCell是我自定义的cell的类型
    [self.collectionView registerClass:[WYCollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    // 注册collectionView头部的view
    [self.collectionView registerClass:[WYCollectionHeaderReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
    // 注册collectionview底部的view
    [self.collectionView registerClass:[WYCollectionFooterReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"footer"];
}

- (void)setupBarButtonItem {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"完成"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(finished:)];
}

- (void)setupData {
    if (self.photos) {
        [self.photos removeAllObjects];
    }else {
        self.photos = [[NSMutableArray alloc] init];
    }
    
    __weak typeof(self) weakSelf = self;
    [self.group enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (obj) {
            WYPhoto *photo = [[WYPhoto alloc] init];
            photo.asset = obj;
            
            [weakSelf.photos addObject:photo];
        }
        
        if (weakSelf.group.count-1 ==idx) {
            [weakSelf.collectionView reloadData];
        }
    }];
}

#pragma mark - Actions

- (void)finished:(id)sender {
    
}

#pragma mark - Getter

- (UICollectionView *)collectionView {
    if (_collectionView == nil) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        // 设置collectionView的滚动方向，需要注意的是如果使用了collectionview的headerview或者footerview的话， 如果设置了水平滚动方向的话，那么就只有宽度起作用了了
        [layout setScrollDirection:UICollectionViewScrollDirectionVertical];
        // layout.minimumInteritemSpacing = 10;// 垂直方向的间距
        // layout.minimumLineSpacing = 10; // 水平方向的间距
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.alwaysBounceVertical = YES;
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
    }
    
    return _collectionView;
}

@end
