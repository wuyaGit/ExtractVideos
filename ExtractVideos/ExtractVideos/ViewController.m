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

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//打开摄像头
- (IBAction)onTouchOpenVideosAction:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    __weak typeof(*&self) weakSelf = self;
    UIAlertAction *pzAction = [UIAlertAction actionWithTitle:@"拍视频" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        [weakSelf openCameraAction];
    }];
    UIAlertAction *xzAction = [UIAlertAction actionWithTitle:@"从手机本地文件选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//        UINavigationController *manageFile = (UINavigationController *)[TSTCommon storyboard:@"Main" wihtIdentifer:@"manageFileNavigationController"];
//        ((ManageSourceFileViewController *)manageFile.visibleViewController).complection = ^(NSMutableArray *array) {
//            UIViewController *viewController = [TSTCommon storyboard:@"Main" wihtIdentifer:@"uploadFilesViewController"];
//            [viewController setValue:array forKey:@"uploadFiles"];
//
//            [weakSelf.navigationController pushViewController:viewController animated:YES];
//        };
//
//        [weakSelf.navigationController presentViewController:manageFile animated:YES completion:nil];
    }];
    UIAlertAction *qxAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:pzAction];
    [alertController addAction:xzAction];
    [alertController addAction:qxAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Private


- (void)openCameraAction {
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

- (void)videoWithSourceType:(UIImagePickerControllerSourceType)type  {
    //获取授权状态
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    //判断当前状态
    if (authStatus == AVAuthorizationStatusRestricted ||
        authStatus == AVAuthorizationStatusDenied) {
        //拒绝访问，提示
        NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
        NSString *tipTextWhenNoPhotosAuthorization = [NSString stringWithFormat:@"请在设备的\"设置-隐私-照片\"选项中，允许%@访问您的手机相册", appName];

        [[[UIAlertView alloc] initWithTitle:@"相册权限受限"
                                    message:tipTextWhenNoPhotosAuthorization
                                   delegate:nil
                          cancelButtonTitle:@"确定"
                          otherButtonTitles:nil] show];
        return;
    }else {
        
    }
    
   
    
}


//http://blog.csdn.net/amydom/article/details/52778244
//http://blog.csdn.net/wsyx768/article/details/50771993
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
        [library performChanges:^{
            assetId = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:sourceURL].placeholderForCreatedAsset.localIdentifier;
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            
        }];
        
    });
    
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end