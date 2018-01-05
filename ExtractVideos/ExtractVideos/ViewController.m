//
//  ViewController.m
//  ExtractVideos
//
//  Created by YANGGL on 2017/12/26.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

#import "WYPhotoLibraryController.h"

static NSString *AssetCollectionName = @"WYPhotoLibrary";

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, WYPhotoLibraryControllerDelegate>

@property (nonatomic, strong) NSMutableArray *videoFiles;

@end

@implementation ViewController


#pragma mark - Cycle life

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.videoFiles = [[NSMutableArray alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Touch Action methods

- (IBAction)onTouchAddVideoAction:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    //ipad使用，不加ipad上会崩溃
    if (alertController.popoverPresentationController) {
        alertController.popoverPresentationController.sourceView = sender;
//        alertController.popoverPresentationController.sourceRect = CGRectMake(self.navigationController.navigationBar.frame.size.width - 90.0,
//                                                                              self.navigationController.navigationBar.frame.origin.y, 90.0,
//                                                                              self.navigationController.navigationBar.frame.size.height);
    }
    
    __weak typeof(*&self) weakSelf = self;
    UIAlertAction *pzAction = [UIAlertAction actionWithTitle:@"拍视频" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        [weakSelf useCameraHandler];
    }];
    UIAlertAction *xzAction = [UIAlertAction actionWithTitle:@"从手机本地文件选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [weakSelf usePhotoLibraryHandler];
    }];
    UIAlertAction *qxAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:pzAction];
    [alertController addAction:xzAction];
    [alertController addAction:qxAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)onTouchDeleteVideoAction:(id)sender {
    NSIndexPath *indexPath = [self indexPathForSuperview:sender];
 
    [self.videoFiles removeObjectAtIndex:indexPath.row];
    [self.tableView reloadData];
}

- (IBAction)onTouchPlayVideoAction:(id)sender {
//    NSIndexPath *indexPath = [self indexPathForSuperview:sender];

}

#pragma mark - Private methods


- (void)useCameraHandler {
    NSString *mediaType = AVMediaTypeVideo;//读取媒体类型
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];//读取设备授权状态
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
        NSString *tipTextWhenNoPhotosAuthorization = @"请在设备的\"设置-隐私-照片\"选项中，允许App访问您的手机相册。";
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"此应用没有权限访问相册"
                                                                                 message:tipTextWhenNoPhotosAuthorization
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *qdAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:qdAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"无摄像头可用"
                                                                                 message:nil
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *qdAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:qdAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    
    //sourcetype有三种分别是camera，photoLibrary和photoAlbum
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    //Camera所支持的Media格式都共有两个：@"public.image",@"public.movie"
    //可以这么写：picker.mediaTypes = [NSArray arrayWithObjects:@"public.movie", nil];
    //或者 picker.mediaTypes = @[(NSString *)kUTTypeMovie];
    picker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
    picker.videoQuality = UIImagePickerControllerQualityTypeMedium; //录像质量
    picker.videoMaximumDuration = 600.0f; //录像最长时间
    picker.delegate = self;
    
    [self presentViewController:picker animated:YES completion:nil];
    
}

- (void)usePhotoLibraryHandler {
    WYPhotoLibraryController *library = [[WYPhotoLibraryController alloc]init];
    library.photoFilterType = WYPhotoFilterAllVideo;
    library.libraryDelegate = self;
    
    [self presentViewController:library animated:YES completion:nil];
}

- (NSIndexPath *)indexPathForSuperview:(id)sender {
    while (![[sender superview] isKindOfClass:[UITableViewCell class]]) {
        sender = [sender superview];
    }
    
    UITableViewCell *cell = (UITableViewCell *)[sender superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    return indexPath;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.videoFiles.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@""];
    if (indexPath.row == self.videoFiles.count) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"addCell"];
    }else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"videoCell"];
        
        WYPhoto *photo = self.videoFiles[indexPath.row];
        [((UILabel *)[cell viewWithTag:13]) setText:photo.name];
        [photo setGetThumbnail:^(UIImage *image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [((UIButton *)[cell viewWithTag:11]) setBackgroundImage:image forState:UIControlStateNormal];
            });
        }];
        [photo setGetFileSize:^(NSInteger fileSize) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [((UILabel *)[cell viewWithTag:12]) setText:[NSString stringWithFormat:@"%.1f MB", fileSize / (1024.0 * 1024.0)]];
            });
        }];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 160.f;
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    NSURL *sourceURL = [info objectForKey:UIImagePickerControllerMediaURL];
    NSLog(@"%@", sourceURL);

    PHPhotoLibrary *library = [PHPhotoLibrary sharedPhotoLibrary];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSError * error = nil;
        __block NSString *assetId = nil; //用来抓取PHAsset的字符串标识
        __block NSString *assetCollectionId = nil;//用来抓取PHAssetCollectin的字符串标识符
        
        //保存视频到【Camera Roll】(相机胶卷)
        [library performChangesAndWait:^{
            assetId = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:sourceURL].placeholderForCreatedAsset.localIdentifier;
        } error:&error];
        
        //获取创建过的自定义视频相册名字
        PHAssetCollection *createAssetCollection = nil;
        PHFetchResult<PHAssetCollection *> *assetCollections = [PHAssetCollection  fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
        for (PHAssetCollection *assetCollection in assetCollections) {
            if ([assetCollection.localizedTitle isEqualToString:AssetCollectionName]) {
                createAssetCollection = assetCollection;
                
                break;
            }
        }
        
        //如果没有自定义相册，创建一个
        if (createAssetCollection == nil) {
            [library performChangesAndWait:^{
                assetCollectionId = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:AssetCollectionName].placeholderForCreatedAssetCollection.localIdentifier;
                
            } error:&error];

            //抓取刚创建完的视频相册对象
            createAssetCollection = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[assetCollectionId] options:nil].firstObject;
        }
        
        //将(相机胶卷)的视频 添加到自定义的相册中
        [library performChangesAndWait:^{
            PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:createAssetCollection];
            
            //视频
            [request addAssets:[PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil]];
        } error:&error];
        
        //提示信息
        if (error) {
            NSLog(@"保存视频失败!");
        } else {
            NSLog(@"保存视频成功!");
        }
    });
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - WYPhotoLibraryControllerDelegate

- (void)photoLibraryController:(WYPhotoLibraryController *)library didFinishPickingPhotos:(NSArray *)photos {
    [library dismissViewControllerAnimated:YES completion:nil];
    
    if (photos.count) {
        [self.videoFiles addObjectsFromArray:photos];
        
        [self.tableView reloadData];
    }
}

- (void)photoLibraryControllerDidCancel:(WYPhotoLibraryController *)library {
    [library dismissViewControllerAnimated:YES completion:nil];
}

@end
