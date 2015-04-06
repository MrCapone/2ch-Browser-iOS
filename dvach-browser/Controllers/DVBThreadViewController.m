//
//  DVBThreadViewController.m
//  dvach-browser
//
//  Created by Andy on 11/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import "DVBConstants.h"
#import "DVBThreadViewController.h"
#import "DVBPostObj.h"
#import "DVBPostTableViewCell.h"
#import "Reachability.h"
#import "DVBBadPost.h"
#import "DVBCreatePostViewController.h"
#import "DVBComment.h"
#import "DVBNetworking.h"
#import "DVBBrowserViewControllerBuilder.h"
#import "DVBThreadModel.h"

static NSString *const POST_CELL_IDENTIFIER = @"postCell";
static NSString *const SEGUE_TO_NEW_POST = @"segueToNewPost";

/*
// default row height
static CGFloat const ROW_DEFAULT_HEIGHT = 101.0f;

// thumbnail width in post row
static CGFloat const THUMBNAIL_WIDTH = 65.f;
//thumbnail contstraints for calculating layout dimentions
static CGFloat const THUMBNAIL_CONSTRAINT_LEFT = 8.0f;
static CGFloat const THUMBNAIL_CONSTRAINT_RIGHT = 8.0f;
// settings for comment textView
static CGFloat const CORRECTION_WIDTH_FOR_TEXT_VIEW_CALC = 30.f;
// Correction from top contstr = 8, bottom contstraint = 8 and border = 1 8+8+1 = 17
static CGFloat const CORRECTION_HEIGHT_FOR_TEXT_VIEW_CALC = 50.0f;
*/

// settings for handling long pressure gesture on table cell
static CGFloat const MINIMUM_PRESS_DURATION = 1.2F;
static CGFloat const ALLOWABLE_MOVEMENT = 100.0f;

@protocol sendDataProtocol <NSObject>

- (void)sendDataToBoard:(NSUInteger)deletedObjectIndex;

@end

@interface DVBThreadViewController () <UIActionSheetDelegate, DVBCreatePostViewControllerDelegate>

// for recofnizing long press on post row
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureOnPicture;

// array of posts inside this thread
@property (nonatomic, strong) NSMutableArray *postsArray;

// model for posts in the thread
@property (nonatomic, strong) DVBThreadModel *threadModel;

// array of all post thumb images in thread
@property (nonatomic, strong) NSMutableArray *thumbImagesArray;
// array of all post full images in thread
@property (nonatomic, strong) NSMutableArray *fullImagesArray;
@property (nonatomic, strong) DVBPostTableViewCell *prototypeCell;

// action sheet for displaying bad posts flaggind (and maybe somethig more later)
@property (nonatomic, strong) UIActionSheet *postLongPressSheet;
@property (nonatomic, strong) NSString *flaggedPostNum;
@property (nonatomic, assign) NSUInteger selectedWithLongPressSection;

@property (nonatomic, assign) NSUInteger updatedTimes;

// storage for bad posts, marked on this specific device
// @property (nonatomic, strong) DVBBadPostStorage *badPostsStorage;

// for marking if OP message already glagged or not (tech prop)
@property (nonatomic, assign) BOOL opAlreadyDeleted;

// test array for new photo browser
@property (nonatomic, strong) NSMutableArray *photos;

// flagging
@property (weak, nonatomic) IBOutlet UIBarButtonItem *flagButton;

@end

@implementation DVBThreadViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // fix wrong cell sizes
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self prepareViewController];
    [self reloadThread];
}

- (void)prepareViewController
{
    _opAlreadyDeleted = NO;
    [self addGestureRecognisers];
    
    if (_answersToPost) {
        [self.navigationController setToolbarHidden:YES animated:NO];
        self.navigationItem.rightBarButtonItem = nil;
        if (!_postNum) {
            @throw [NSException exceptionWithName:@"No post number specified for answers" reason:@"Please, set postNum to show in title of the VC" userInfo:nil];
        }
        else {
            NSString *answerTitle = NSLocalizedString(@"Ответы к", @"ThreadVC title if we show answers for specific post");
            self.title = [NSString stringWithFormat:@"%@ %@", answerTitle, _postNum];
        }
        _threadModel = [[DVBThreadModel alloc] init];
        
        NSArray *arrayOfThumbs = [_threadModel thumbImagesArrayForPostsArray:_answersToPost];
        _thumbImagesArray = [arrayOfThumbs mutableCopy];
        
        NSArray *arrayOfFullImages = [_threadModel fullImagesArrayForPostsArray:_answersToPost];
        _fullImagesArray = [arrayOfFullImages mutableCopy];

        NSLog(@"count of thumbs: %ld", [_thumbImagesArray count]);
    }
    else {
        [self.navigationController setToolbarHidden:NO animated:NO];
        // Set view controller title depending on...
        self.title = [self getSubjectOrNumWithSubject:_threadSubject
                                         andThreadNum:_threadNum];
        _threadModel = [[DVBThreadModel alloc] initWithBoardCode:_boardCode
                                                    andThreadNum:_threadNum];
    }
    
    // self.tableView.estimatedRowHeight = 100;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

#pragma mark - Set titles and gestures

- (NSString *)getSubjectOrNumWithSubject:(NSString *)subject
                            andThreadNum:(NSString *)num
{
    /**
     *  If thread Subject is empty - return OP post number
     */
    BOOL isSubjectEmpty = [subject isEqualToString:@""];
    if (isSubjectEmpty)
    {
        return num;
    }
    
    return subject;
}

- (void)addGestureRecognisers
{
    // setting for long pressure gesture
    _longPressGestureOnPicture = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                               action:@selector(handleLongPressGestures:)];
    _longPressGestureOnPicture.minimumPressDuration = MINIMUM_PRESS_DURATION;
    _longPressGestureOnPicture.allowableMovement = ALLOWABLE_MOVEMENT;
    
    [self.tableView addGestureRecognizer:_longPressGestureOnPicture];
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_postsArray count];
}
/**
 *  Set every section title depending on post SUBJECT or NUMBER
 */
- (NSString *)tableView:(UITableView *)tableView
titleForHeaderInSection:(NSInteger)section
{
    DVBPostObj *postTmpObj = _postsArray[section];
    NSString *subject = postTmpObj.subject;
    NSString *date = postTmpObj.date;
    
    subject = [self getSubjectOrNumWithSubject:subject
                                  andThreadNum:postTmpObj.num];
    
    // we increase number by one because sections start count from 0 and post counts on 2ch commonly start with 1
    NSInteger postNumToShow = section + 1;
    
    NSString *sectionTitle = [[NSString alloc] initWithFormat:@"#%ld %@ - %@", (long)postNumToShow, subject, date];
    
    return sectionTitle;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // only one row inside every section for now
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DVBPostTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:POST_CELL_IDENTIFIER
                                                                 forIndexPath:indexPath];
    [self configureCell:cell
      forRowAtIndexPath:indexPath];
    
    return cell;
}
/*
- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // I am using a helper method here to get the text at a given cell.
    NSAttributedString *text = [self getTextAtIndex:indexPath];
    
    // Getting the width/height needed by the dynamic text view.

    CGSize viewSize = self.tableView.bounds.size;
    NSInteger viewWidth = viewSize.width;
    
    // Set default difference (if we hve image in the cell).
    CGFloat widthDifferenceBecauseOfImage = THUMBNAIL_WIDTH + THUMBNAIL_CONSTRAINT_LEFT + THUMBNAIL_CONSTRAINT_RIGHT;
    
    // Determine if we really have image in the cell.
    DVBPostObj *postObj = _postsArray[indexPath.section];
    NSString *thumbPath = postObj.thumbPath;
    
    // If not - then set the difference to 0.
    if ([thumbPath isEqualToString:@""])
    {
        widthDifferenceBecauseOfImage = 0;
    }
    
    // we decrease window width value by taking off elements and contraints values
    CGFloat textViewWidth = viewWidth - widthDifferenceBecauseOfImage;
    
    // correcting width by magic number
    CGFloat width = textViewWidth - CORRECTION_WIDTH_FOR_TEXT_VIEW_CALC;
    
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    CGSize size = [self frameForText:text
                        sizeWithFont:font
                   constrainedToSize:CGSizeMake(width, CGFLOAT_MAX)];
    
    // Return the size of the current row.
    // 81 is the minimum height! Update accordingly
    CGFloat heightToReturn = size.height;
    
    CGFloat heightForReturnWithCorrectionAndCeilf = ceilf(heightToReturn + CORRECTION_HEIGHT_FOR_TEXT_VIEW_CALC);
    
    if (heightToReturn < ROW_DEFAULT_HEIGHT)
    {
        if ([thumbPath isEqualToString:@""])
        {
            return heightForReturnWithCorrectionAndCeilf;
        }
        
        return ROW_DEFAULT_HEIGHT;
    }
    
    return heightForReturnWithCorrectionAndCeilf;
}
*/
/**
 *  For more smooth and fast user expierence (iOS 8).
 */
- (CGFloat)tableView:(UITableView *)tableView
estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DVBPostObj *selectedPost = _postsArray[indexPath.section];
    // NSString *thumbUrl = selectedPost.thumbPath;
    
    NSString *fullUrlString = selectedPost.path;
    
    // Check if cell have real image / webm video or just placeholder
    if (![fullUrlString isEqualToString:@""])
    {
        // if contains .webm
        if ([fullUrlString rangeOfString:@".webm" options:NSCaseInsensitiveSearch].location != NSNotFound)
        {
            NSURL *fullUrl = [NSURL URLWithString:fullUrlString];
            BOOL canOpenInVLC = [[UIApplication sharedApplication] canOpenURL:fullUrl];
            
            if (canOpenInVLC)
            {
                [[UIApplication sharedApplication] openURL:fullUrl];
            }
            else
            {
                NSLog(@"Need VLC to open this");
                NSString *installVLCPrompt = NSLocalizedString(@"Для просмотра установите VLC", @"Prompt in navigation bar of a thread View Controller - shows after user tap on the video and if user do not have VLC on the device");
                self.navigationItem.prompt = installVLCPrompt;
                [self performSelector:@selector(clearPrompt)
                           withObject:nil
                           afterDelay:2.0];
            }
        }
        // if not
        else
        {
            [self handleTapOnImageViewWithIndexPath:indexPath];
        }
    }
    
}
// Clear prompt of any status / error messages
- (void)clearPrompt
{
    self.navigationItem.prompt = nil;
}

#pragma mark - Cell configuration and calculation

- (void)configureCell:(UITableViewCell *)cell
    forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[DVBPostTableViewCell class]])
    {
        DVBPostTableViewCell *confCell = (DVBPostTableViewCell *)cell;
        
        DVBPostObj *postTmpObj = _postsArray[indexPath.section];
        
        NSString *thumbUrlString = postTmpObj.thumbPath;
        NSUInteger indexForButton = indexPath.section;
        
        [confCell prepareCellWithCommentText:postTmpObj.comment
                       andPostThumbUrlString:thumbUrlString
                         andPostRepliesCount:[postTmpObj.replies count]
                                    andIndex:indexForButton];

    }
}
/**
 *  Think of this as some utility function that given text, calculates how much space we need to fit that text. Calculation for texView height.
 */
-(CGSize)frameForText:(NSAttributedString *)text
         sizeWithFont:(UIFont *)font
    constrainedToSize:(CGSize)size
{
    CGRect frame = [text boundingRectWithSize:size
                                      options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                      context:nil];
    
    /**
     *  This contains both height and width, but we really care about height.
     */
    return frame.size;
}

/**
 *  Think of this as a source for the text to be rendered in the text view.
 *  I used a dictionary to map indexPath to some dynamically fetched text.
 */
- (NSAttributedString *)getTextAtIndex:(NSIndexPath *)indexPath
{
    
    NSUInteger tmpIndex = indexPath.section;
    DVBPostObj *tmpObj =  _postsArray[tmpIndex];
    NSAttributedString *tmpComment = tmpObj.comment;
    
    return tmpComment;
}

#pragma mark - Data management and processing

/**
 *  Get data from 2ch server
 *
 *  @param board      <#board description#>
 *  @param threadNum  <#threadNum description#>
 *  @param completion <#completion description#>
 */
- (void)getPostsWithBoard:(NSString *)board
                andThread:(NSString *)threadNum
            andCompletion:(void (^)(NSArray *))completion
{
    [_threadModel reloadThreadWithCompletion:^(NSArray *completionsPosts) {
        _postsArray = _threadModel.postsArray;
        _thumbImagesArray = _threadModel.thumbImagesArray;
        _fullImagesArray = _threadModel.fullImagesArray;
        completion(completionsPosts);
    }];
}

// reload thread by current thread num
- (void)reloadThread {
    if (_answersToPost) {
        _postsArray = [_answersToPost mutableCopy];
    }
    else {
        [self getPostsWithBoard:_boardCode
                      andThread:_threadNum
                  andCompletion:^(NSArray *postsArrayBlock)
        {
            _postsArray = [postsArrayBlock mutableCopy];
        }];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)reloadThreadFromOutside
{
    [self reloadThread];
}

#pragma mark - Actions from Storyboard

- (IBAction)reloadThreadAction:(id)sender
{
    [self reloadThread];
}

- (IBAction)scrollToTop:(id)sender
{
    CGPoint pointToScrollTo = CGPointMake(0, 0 - self.tableView.contentInset.top);
    [self.tableView setContentOffset:pointToScrollTo animated:YES];
}

- (IBAction)scrollToBottom:(id)sender
{
    CGPoint pointToScrollTo = CGPointMake(0, self.tableView.contentSize.height - self.tableView.frame.size.height);
    [self.tableView setContentOffset:pointToScrollTo animated:YES];
}

- (IBAction)showAnswers:(id)sender
{
    UIButton *answerButton = sender;
    NSUInteger buttonClickedIndex = answerButton.tag;
    DVBPostObj *post = _postsArray[buttonClickedIndex];
    DVBThreadViewController *threadViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"DVBThreadViewController"];
    NSString *postNum = post.num;
    threadViewController.postNum = postNum;
    threadViewController.answersToPost = post.replies;
    [self.navigationController pushViewController:threadViewController animated:YES];
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier
                                  sender:(id)sender
{
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
    if ([[segue identifier] isEqualToString:SEGUE_TO_NEW_POST])
    {
        DVBCreatePostViewController *createPostViewController = (DVBCreatePostViewController*) [[segue destinationViewController] topViewController];
        
        createPostViewController.threadNum = _threadNum;
        createPostViewController.boardCode = _boardCode;
        createPostViewController.createPostViewControllerDelegate = self;
    }
}

- (void)handleLongPressGestures:(UILongPressGestureRecognizer *)gestureRecognizer
{
    // try to understand on which cell we performed long press gesture
    CGPoint p = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        
        DVBPostObj *postObj = [_postsArray objectAtIndex:indexPath.section];
        
        // setting variable to bad post number (we'll use it soon)
        _flaggedPostNum = postObj.num;
        
        _selectedWithLongPressSection = (NSUInteger)indexPath.section;
        _postLongPressSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                          delegate:self
                                                 cancelButtonTitle:@"Отмена"
                                            destructiveButtonTitle:nil
                                                 otherButtonTitles:@"Ответить", @"Открыть в браузере", @"Пожаловаться", nil];
        
        [_postLongPressSheet showInView:self.tableView];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet
didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
    if (actionSheet == _postLongPressSheet)
    {
        switch (buttonIndex)
        {
                
            case 0:
            {
                // add post answer to comment and make segue
                DVBComment *sharedComment = [DVBComment sharedComment];
                
                NSString *oldCommentText = sharedComment.comment;
                
                DVBPostObj *post = [_postsArray objectAtIndex:_selectedWithLongPressSection];
                
                NSString *postNum = post.num;
                
                NSString *newStringOfComment = @"";
                
                // first one is for creating blank comment
                if ([oldCommentText isEqualToString:@""])
                {
                    newStringOfComment = [[NSString alloc] initWithFormat:@">>%@\n", postNum];
                }
                
                // second one works when there is some text in comment already
                else
                {
                    newStringOfComment = [[NSString alloc] initWithFormat:@"\n>>%@\n", postNum];
                }

                NSString *commentToSingleton = [[NSString alloc] initWithFormat:@"%@%@", oldCommentText, newStringOfComment];
                
                sharedComment.comment = commentToSingleton;
                
                NSLog(@"%@", sharedComment.comment);
                [self performSegueWithIdentifier:SEGUE_TO_NEW_POST
                                          sender:self];
                break;
            }
                
            case 1:
            {
                // open in browser button
                NSString *urlToOpen = [[NSString alloc] initWithFormat:@"%@%@/res/%@.html", DVACH_BASE_URL, _boardCode, _threadNum];
                NSLog(@"URL: %@", urlToOpen);
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlToOpen]];
                break;
            }
                
            case 2:
            {
                // Flag button
                [self sendPost:_flaggedPostNum andBoard:_boardCode andCompletion:^(BOOL done) {
                    NSLog(@"Post complaint sent.");
                    if (done)
                    {
                        [self deletePostWithIndex:_selectedWithLongPressSection fromMutableArray:_postsArray andFlaggedPostNum:_flaggedPostNum];
                    }
                }];
                break;
            }
            default:
            {
                break;
            }
        }
    }
}

#pragma mark - Bad posts reporting

/**
 *  Function for flag inappropriate content and send it to moderators DB.
 */
- (void) sendPost:(NSString *)postNum
         andBoard:(NSString *)board
    andCompletion:(void (^)(BOOL ))completion
{
    NSString *currentPostNum = postNum;
    NSString *currentBoard = board;
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable)
    {
        NSLog(@"Cannot find internet.");
        BOOL result = NO;
        return completion(result);
    }
    else
    {
        
        // building URL for sendin JSON to my server (for tickets)
        // there is better one-line solution for this - need to use stringWithFormat
        // rewrite in future!
        
        NSMutableString *requestAddress = [[NSMutableString alloc] initWithString:COMPLAINT_URL];
        [requestAddress appendString:@"?postnum="];
        [requestAddress appendString:currentPostNum];
        [requestAddress appendString:@"&board="];
        [requestAddress appendString:currentBoard];
        
        NSURLRequest *activeRequest = [NSURLRequest requestWithURL:
                                       [NSURL URLWithString:requestAddress]];
        
        [NSURLConnection sendAsynchronousRequest:activeRequest
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response,
                                                   NSData *data,
                                                   NSError *connectionError)
         {
             NSError *jsonError;
             
             NSMutableDictionary *resultDict = [NSJSONSerialization JSONObjectWithData:data
                                                                               options:NSJSONReadingAllowFragments
                                                                                 error:&jsonError];
             
             NSString *status = resultDict[@"status"];
             
             BOOL ok = YES;
             
             if (![status isEqualToString:@"1"])
             {
                 completion(NO);
             }
             
             completion(ok);
         }];
    }
}

- (void)deletePostWithIndex:(NSUInteger)index
           fromMutableArray:(NSMutableArray *)array
          andFlaggedPostNum:(NSString *)flaggedPostNum
{
    [_threadModel flagPostWithIndex:index andFlaggedPostNum:flaggedPostNum andOpAlreadyDeleted:_opAlreadyDeleted];
    
    if (index == 0)
    {
        [self.delegate sendDataToBoard:_threadIndex];
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        [self.tableView reloadData];
        [self showAlertAboutReportedPost];
    }
}

- (void)showAlertAboutReportedPost
{
    NSString *complaintSentAlertTitle = NSLocalizedString(@"Жалоба отправлена", @"Заголовок alert'a сообщает о том, что жалоба отправлена.");
    NSString *complaintSentAlertMessage = NSLocalizedString(@"Ваша жалоба посталена в очередь на проверку модератором. Пост был скрыт.", @"Текст alert'a сообщает о том, что жалоба отправлена.");
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:complaintSentAlertTitle
                                                        message:complaintSentAlertMessage
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
    [alertView setTag:1];
    [alertView show];
}

- (IBAction)reportButtonAction:(id)sender
{
    /**
     *  Report entire thread (all for mods).
     */
    [self sendPost:_threadNum andBoard:_boardCode andCompletion:^(BOOL done)
    {
        NSLog(@"Post complaint sent.");
        if (done)
        {
            [self deletePostWithIndex:_selectedWithLongPressSection fromMutableArray:_postsArray andFlaggedPostNum:_flaggedPostNum];
        }
    }];
}

#pragma mark - Photo gallery

// Tap on image method
- (void)handleTapOnImageViewWithIndexPath:(NSIndexPath *)indexPath
{
    [self createAndPushGalleryWithIndexPath:indexPath];
}

- (void)createAndPushGalleryWithIndexPath:(NSIndexPath *)indexPath
{
    DVBBrowserViewControllerBuilder *galleryBrowser = [[DVBBrowserViewControllerBuilder alloc] initWithDelegate:nil];

    NSUInteger indexForImageShowing = indexPath.section;
    DVBPostObj *postObj = _postsArray[indexForImageShowing];
    NSString *path = postObj.path;
    NSUInteger index = [_fullImagesArray indexOfObject:path];

    galleryBrowser.index = index;
    
    [galleryBrowser prepareWithIndex:index
          andThumbImagesArray:_thumbImagesArray
           andFullImagesArray:_fullImagesArray];

    // Present
    [self.navigationController pushViewController:galleryBrowser animated:YES];
}

#pragma mark - DVBCreatePostViewControllerDelegate

-(void)updateThreadAfterPosting
{
    /**
     *  Update thread from network.
     */
    [self reloadThread];
    /**
     *  Scroll thread to bottom. Not working as it should for now.
     */
    CGPoint pointToScrollTo = CGPointMake(0, self.tableView.contentSize.height - self.tableView.frame.size.height);
    [self.tableView setContentOffset:pointToScrollTo animated:YES];
    
    NSLog(@"Table updated after posting.");
}

@end