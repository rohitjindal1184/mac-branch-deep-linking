//
//  MonsterCreatorViewController.m
//  BranchMonsterFactory
//
//  Created by Alex Austin on 9/6/14.
//  Copyright (c) 2014 Branch, Inc All rights reserved.
//

#import "MonsterCreatorViewController.h"
#import "MonsterPartsFactory.h"
#import "ImageCollectionViewCell.h"
#import "MonsterViewerViewController.h"
#import "BranchUniversalObject+MonsterHelpers.h"
@import Branch;

@interface MonsterCreatorViewController ()
    <UICollectionViewDataSource,
     UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField        *monsterName;
@property (weak, nonatomic) IBOutlet UIView             *botViewLayerOne;
@property (weak, nonatomic) IBOutlet UICollectionView   *botViewLayerTwo;
@property (weak, nonatomic) IBOutlet UICollectionView   *botViewLayerThree;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray*colorViews;

@property (weak, nonatomic) IBOutlet UIButton *cmdUpArrow;
@property (weak, nonatomic) IBOutlet UIButton *cmdDownArrow;
@property (weak, nonatomic) IBOutlet UIButton *cmdLeftArrow;
@property (weak, nonatomic) IBOutlet UIButton *cmdRightArrow;
@property (weak, nonatomic) IBOutlet UIButton *cmdDone;

@property (nonatomic) NSInteger bodyIndex;
@property (nonatomic) NSInteger faceIndex;
@end

#pragma mark - MonsterCreatorViewController

@implementation MonsterCreatorViewController

+ (MonsterCreatorViewController*) viewControllerWithMonster:(BranchUniversalObject*)monster {
    UIStoryboard*storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    MonsterCreatorViewController*controller =
        [storyBoard instantiateViewControllerWithIdentifier:NSStringFromClass(self)];
    controller.monster = monster;
    return controller;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (!self.monster)
        self.monster = [BranchUniversalObject emptyMonster];

    for (int i = 0; i < [self.colorViews count]; i++) {
        UIButton *currView = [self.colorViews objectAtIndex:i];
        currView.backgroundColor = [MonsterPartsFactory colorForIndex:i];

        if (i == [self.monster colorIndex])
            [currView.layer setBorderWidth:2.0f];
        else
            [currView.layer setBorderWidth:0.0f];
        currView.layer.borderColor = [UIColor colorWithWhite:0.3 alpha:1.0].CGColor;

        [currView addTarget:self
            action:@selector(cmdColorClick:)
            forControlEvents:UIControlEventPrimaryActionTriggered];
    }

    self.cmdUpArrow.backgroundColor = UIColor.whiteColor;
    self.cmdDownArrow.backgroundColor = UIColor.whiteColor;
    self.cmdLeftArrow.backgroundColor = UIColor.whiteColor;
    self.cmdRightArrow.backgroundColor = UIColor.whiteColor;
    self.cmdDone.backgroundColor = [MonsterPartsFactory colorForIndex:5];

    self.botViewLayerOne.layer.backgroundColor =
        [MonsterPartsFactory colorForIndex:[self.monster colorIndex]].CGColor;
    
    self.botViewLayerTwo.delegate = self;
    self.botViewLayerTwo.dataSource = self;
    [self.botViewLayerTwo registerClass:[ImageCollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    
    self.botViewLayerThree.delegate = self;
    self.botViewLayerThree.dataSource = self;
    [self.botViewLayerThree registerClass:[ImageCollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    
    [self.monsterName setText:[self.monster monsterName]];
}

- (void)viewDidLayoutSubviews {
    self.bodyIndex = [self.monster bodyIndex];
    self.faceIndex = [self.monster faceIndex];
    [self.botViewLayerTwo scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.bodyIndex inSection:0]
        atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
        animated:NO];
    [self.botViewLayerThree scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.faceIndex inSection:0]
        atScrollPosition:UICollectionViewScrollPositionCenteredVertically
        animated:NO];
}

- (IBAction)cmdLeftClick:(id)sender {
    self.bodyIndex = self.bodyIndex - 1;
    if (self.bodyIndex == -1)
        self.bodyIndex = [MonsterPartsFactory sizeOfBodyArray] - 1;
    [self.monster setBodyIndex:self.bodyIndex];
    [self.botViewLayerTwo
        scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.bodyIndex inSection:0]
        atScrollPosition:
            UICollectionViewScrollPositionCenteredHorizontally |
            UICollectionViewScrollPositionCenteredVertically
        animated:YES];
}

- (IBAction)cmdRightClick:(id)sender {
    self.bodyIndex = self.bodyIndex + 1;
    if (self.bodyIndex == [MonsterPartsFactory sizeOfBodyArray])
        self.bodyIndex = 0;
    [self.monster setBodyIndex:self.bodyIndex];
    [self.botViewLayerTwo scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.bodyIndex inSection:0]
        atScrollPosition:
            UICollectionViewScrollPositionCenteredHorizontally |
            UICollectionViewScrollPositionCenteredVertically
        animated:YES];
}

- (IBAction)cmdUpClick:(id)sender {
    self.faceIndex = self.faceIndex - 1;
    if (self.faceIndex == -1)
        self.faceIndex = [MonsterPartsFactory sizeOfFaceArray] - 1;
    [self.monster setFaceIndex:self.faceIndex];
    [self.botViewLayerThree scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.faceIndex inSection:0]
        atScrollPosition:UICollectionViewScrollPositionCenteredVertically
        animated:YES];
}

- (IBAction)cmdDownClick:(id)sender {
    self.faceIndex = self.faceIndex + 1;
    if (self.faceIndex == [MonsterPartsFactory sizeOfFaceArray])
        self.faceIndex = 0;
    [self.monster setFaceIndex:self.faceIndex];
    [self.botViewLayerThree scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.faceIndex inSection:0]
        atScrollPosition:UICollectionViewScrollPositionCenteredVertically
        animated:YES];
}

- (IBAction)cmdColorClick:(id)sender {
    UIButton *currColorButton = (UIButton *)sender;
    
    int selected = 0;
    for (int i = 0; i < [self.colorViews count]; i++) {
        UIButton *button = (UIButton *)[self.colorViews objectAtIndex:i];
        [button.layer setBorderWidth:0.0f];
        if ([button isEqual:currColorButton]) {
            selected = i;
        }
    }
    
    [self.monster setColorIndex:selected];
    [self.botViewLayerOne setBackgroundColor:[MonsterPartsFactory colorForIndex:selected]];
    // [currColorButton setSelected:YES];
    currColorButton.layer.borderWidth = 2.0f;
}

- (IBAction)cmdFinishedClick:(id)sender {
    if ([self.monsterName.text length]) {
        [self.monster setMonsterName:[self.monsterName text]];
    } else {
        [self.monster setMonsterName:@"Bingles Jingleheimer"];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if ([collectionView isEqual:self.botViewLayerTwo]) {
        return [MonsterPartsFactory sizeOfBodyArray];
    } else {
        return [MonsterPartsFactory sizeOfFaceArray];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.botViewLayerOne.frame.size.width, self.botViewLayerOne.frame.size.height);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ImageCollectionViewCell *cell =
        (ImageCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"cell"
           forIndexPath:indexPath];
    
    if ([collectionView isEqual:self.botViewLayerTwo]) {
        UIImage *bodyImage = [MonsterPartsFactory imageForBody:indexPath.row];
        [cell.imageView setImage:bodyImage];
    } else {
        UIImage *faceImage = [MonsterPartsFactory imageForFace:indexPath.row];
        [cell.imageView setImage:faceImage];
        [cell bringSubviewToFront:cell.imageView];
    }
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    MonsterViewerViewController *receiver = (MonsterViewerViewController *)[segue destinationViewController];
    receiver.monster = self.monster;
}

- (IBAction)openTestBedScheme:(id)sender {
    NSURL*URL = [NSURL URLWithString:@"testbed-mac://testbed-mac.app.link/KUfCVJ7LnP"];
    [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
}

- (IBAction)openTestBedUniversal:(id)sender {
    NSURL*URL = [NSURL URLWithString:@"https://testbed-mac.app.link/KUfCVJ7LnP"];
    [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:^ (BOOL success) {
        if (success) return;
        UIAlertController* alert =
            [UIAlertController alertControllerWithTitle:@"Open Failed"
                message:[NSString stringWithFormat:@"Can't open the URL '%@'.", URL.absoluteString]
                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction*defaultAction =
            [UIAlertAction actionWithTitle:@"OK"
                style:UIAlertActionStyleDefault
                handler:nil];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

@end
