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
#import "NSString+HTML.h"
#import "Reachability.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "DVBBadPost.h"
#import "DVBBadPostStorage.h"
#import "DVBCreatePostViewController.h"
#import "DVBComment.h"
#import "DVBNetworking.h"
#import "DVBStatus.h"

static NSString *const POST_CELL_IDENTIFIER = @"postCell";
static NSString *const SEGUE_TO_NEW_POST = @"segueToNewPost";

/**
 *  Too much magic numbers for iOS 7. Need to rewrite somehow.
 */

// default row height
static CGFloat const ROW_DEFAULT_HEIGHT = 81.0f;

// thumbnail width in post row
static CGFloat const THUMBNAIL_WIDTH = 65.f;
//thumbnail contstraints for calculating layout dimentions
static CGFloat const THUMBNAIL_CONSTRAINT_LEFT = 8.0f;
static CGFloat const THUMBNAIL_CONSTRAINT_RIGHT = 8.0f;

// settings for handling long pressure gesture on table cell
static CGFloat const MINIMUM_PRESS_DURATION = 1.2F;
static CGFloat const ALLOWABLE_MOVEMENT = 100.0f;

// settings for comment textView
static CGFloat const CORRECTION_WIDTH_FOR_TEXT_VIEW_CALC = 30.f; // magical number of 30 - to correct width of container while calculating enough size for view to shop comment text
/**
 *  Correction from top contstr = 8, bottom contstraint = 8 and border = 1 8+8+1 = 17
 */
static CGFloat const CORRECTION_HEIGHT_FOR_TEXT_VIEW_CALC = 17.0f;

static CGFloat const TEXTVIEW_INSET = 8;

@protocol sendDataProtocol <NSObject>

- (void)sendDataToBoard:(NSUInteger)deletedObjectIndex;

@end

@interface DVBThreadViewController () <UIActionSheetDelegate, MWPhotoBrowserDelegate, DVBCreatePostViewControllerDelegate>

// for recofnizing long press on post row
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureOnPicture;

// array of posts inside this thread
@property (nonatomic, strong) NSMutableArray *postsArray;

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
@property (nonatomic, strong) DVBBadPostStorage *badPostsStorage;

// for marking if OP message already glagged or not (tech prop)
@property (nonatomic, assign) BOOL opAlreadyDeleted;

// test array for new photo browser
@property (nonatomic, strong) NSMutableArray *photos;

// flagging
@property (weak, nonatomic) IBOutlet UIBarButtonItem *flagButton;

@end

@implementation DVBThreadViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self prepareViewController];
    [self reloadThread];
}

- (void)prepareViewController
{
    [self.navigationController setToolbarHidden:NO animated:NO];
    /**
     *  Set view controller title depending on...
     */
    self.title = [self getSubjectOrNumWithSubject:_threadSubject
                                     andThreadNum:_threadNum];
    [self addGestureRecognisers];
    
    /**
     Handling bad posts on this device
     */
    _badPostsStorage = [[DVBBadPostStorage alloc] init];
    NSString *path = [_badPostsStorage badPostsArchivePath];
    
    _badPostsStorage.badPostsArray = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    if (!_badPostsStorage.badPostsArray)
    {
        _badPostsStorage.badPostsArray = [[NSMutableArray alloc] initWithObjects: nil];
    }
    
    _opAlreadyDeleted = NO;
}

#pragma mark - Set titles and gestures

- (NSString *)getSubjectOrNumWithSubject:(NSString *)subject
                            andThreadNum:(NSString *)num
{
    /**
     *  If thread Subject is empty - return OP post number
     */
    if ([subject isEqualToString:@""])
    {
        return num;
    }
    
    return subject;
}

- (void)addGestureRecognisers
{
    
    // setting for long pressure gesture
    _longPressGestureOnPicture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGestures:)];
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
    
    subject = [self getSubjectOrNumWithSubject:subject
                                  andThreadNum:postTmpObj.num];
    
    // we increase number by one because sections start count from 0 and post counts on 2ch commonly start with 1
    NSInteger postNumToShow = section + 1;
    
    NSString *sectionTitle = [[NSString alloc] initWithFormat:@"#%ld %@", (long)postNumToShow, subject];
    
    return sectionTitle;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
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

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // I am using a helper method here to get the text at a given cell.
    NSString *text = [self getTextAtIndex:indexPath];
    
    // Getting the width/height needed by the dynamic text view.
    
    CGSize viewSize = self.tableView.bounds.size;
    NSInteger viewWidth = viewSize.width;
    
    /**
     *  Set default difference (if we hve image in the cell).
     */
    CGFloat widthDifferenceBecauseOfImage = THUMBNAIL_WIDTH + THUMBNAIL_CONSTRAINT_LEFT + THUMBNAIL_CONSTRAINT_RIGHT;
    
    /**
     *  Determine if we really have image in the cell.
     */
    DVBPostObj *postObj = _postsArray[indexPath.section];
    NSString *thumbPath = postObj.thumbPath;
    
    /**
     *  If not - then set the difference to 0.
     */
    if ([thumbPath isEqualToString:@""])
    {
        widthDifferenceBecauseOfImage = 0;
    }
    
    // we decrease window width value by taking off elements and contraints values
    CGFloat textViewWidth = viewWidth - widthDifferenceBecauseOfImage;
    
    // correcting width by magic number
    CGFloat width = textViewWidth - CORRECTION_WIDTH_FOR_TEXT_VIEW_CALC;
    
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    CGSize size = [self frameForText:text sizeWithFont:font constrainedToSize:CGSizeMake(width, CGFLOAT_MAX)];
    
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
    NSString *thumbUrl = selectedPost.thumbPath;
    
    // check if cell have real image or just placeholder
    if (![thumbUrl isEqualToString:@""])
    {
        [self handleTapOnImageViewWithIndexPath:indexPath];
    }
    
}

#pragma mark - Cell configuration and calculation

- (void)configureCell:(UITableViewCell *)cell
    forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[DVBPostTableViewCell class]])
    {
        DVBPostTableViewCell *confCell = (DVBPostTableViewCell *)cell;
        
        DVBPostObj *postTmpObj = _postsArray[indexPath.section];
        
        /**
         *  This is the first part of the fix for fixing broke links in comments.
         */
        confCell.commentTextView.text = nil;
        
        
        NSString *stringForTextView = [postTmpObj.comment stringByTrimmingCharactersInSet:
                             [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        /**
         *  This is the second part of the fix for fixing broke links in comments.
         */
        stringForTextView = [NSString stringWithFormat:@"%@%@", @"\u200B", stringForTextView];
        
        confCell.commentTextView.text = stringForTextView;
        confCell.commentTextView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        
        // make insets
        [confCell.commentTextView  setTextContainerInset:UIEdgeInsetsMake(TEXTVIEW_INSET, TEXTVIEW_INSET, TEXTVIEW_INSET, TEXTVIEW_INSET)];
        
        // for more tidy images and keep aspect ratio
        confCell.postThumb.contentMode = UIViewContentModeScaleAspectFill;
        confCell.postThumb.clipsToBounds = YES;
        
        // load the image and setting image source depending on presented image or set blank image
        // need to rewrite it to use different table cells if there is no image in post
        if (![postTmpObj.thumbPath isEqualToString:@""])
        {
            [confCell.postThumb sd_setImageWithURL:[NSURL URLWithString:postTmpObj.thumbPath]
                                  placeholderImage:[UIImage imageNamed:@"Noimage.png"]];
            [confCell rebuildPostThumbImageWithImagePresence:YES];
        }
        else
        {
            confCell.postThumb.image = [UIImage imageNamed:@"Noimage.png"];
            [confCell rebuildPostThumbImageWithImagePresence:NO];
        }
    }
}
/**
 *  Think of this as some utility function that given text, calculates how much space we need to fit that text. Calculation for texView height.
 */
-(CGSize)frameForText:(NSString*)text
         sizeWithFont:(UIFont*)font
    constrainedToSize:(CGSize)size
{
    
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          font, NSFontAttributeName,
                                          nil];
    CGRect frame = [text boundingRectWithSize:size
                                      options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                   attributes:attributesDictionary
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
- (NSString *)getTextAtIndex:(NSIndexPath *)indexPath {
    
    NSUInteger tmpIndex = indexPath.section;
    DVBPostObj *tmpObj =  _postsArray[tmpIndex];
    NSString *tmpComment = tmpObj.comment;
    
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
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable)
    {
        NSLog(@"Cannot find internet.");
        NSArray *result = [[NSArray alloc] initWithObjects:@"",nil];
        return completion(result);
    }
    else
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        NSMutableArray *postsFullMutArray = [NSMutableArray array];
        
        self.thumbImagesArray = [[NSMutableArray alloc] init];
        self.fullImagesArray = [[NSMutableArray alloc] init];
        
        // building URL for getting JSON-thread-answer from mutiple strings
        // there is better one-line solution for this - need to use stringWithFormat
        // rewrite in future!
        
        NSMutableString *requestAddress = [NSMutableString stringWithString:DVACH_BASE_URL];
        [requestAddress appendString:board];
        [requestAddress appendString:@"/res/"];
        [requestAddress appendString:threadNum];
        [requestAddress appendString:@".json"];
        
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
           
           NSArray *threadsDict = [resultDict objectForKey:@"threads"];
           NSDictionary *postsArray = [threadsDict objectAtIndex:0];
           NSArray *posts2Array = [postsArray objectForKey:@"posts"];
           
           for (id key in posts2Array)
           {
               NSString *num = [[key objectForKey:@"num"] stringValue];
               
               // server gives me number but I need string
               NSString *tmpNumForPredicate = [[key objectForKey:@"num"] stringValue];
               
               //searching for bad posts
               NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.num contains[cd] %@", tmpNumForPredicate];
               NSArray *filtered = [self.badPostsStorage.badPostsArray filteredArrayUsingPredicate:predicate];
               
               if ([filtered count] > 0)
               {
                   continue;
               }
               
               NSString *comment = [key objectForKey:@"comment"];
               NSString *subject = [key objectForKey:@"subject"];
               
               // replacing regular BR with our own strange NEWLINE "tag" - so nxt method wont entirely wipe BreakLine functionality
               comment = [comment stringByReplacingOccurrencesOfString:@"<br>"
                                                            withString:@":::newline:::"];
               
               // deleteing HTML markup from comment text
               comment = [comment stringByConvertingHTMLToPlainText];
               
               // replacing our weird NEWLINE tag with regular cocoa breakline symbol
               comment = [comment stringByReplacingOccurrencesOfString:@":::newline:::"
                                                            withString:@"\n"];
               
               NSDictionary *files = [[key objectForKey:@"files"] objectAtIndex:0];
               
               NSMutableString *thumbPathMut;
               NSMutableString *picPathMut;
               
               if (files != nil)
               {
                   
                   // check webm or not
                   NSString *fullFileName = [files objectForKey:@"path"];
                   if ([fullFileName rangeOfString:@".webm" options:NSCaseInsensitiveSearch].location != NSNotFound)
                   {
                       
                       // if contains .webm
                       thumbPathMut = [[NSMutableString alloc] initWithString:@""];
                       picPathMut = [[NSMutableString alloc] initWithString:@""];
                       
                   }
                   else
                   {
                       
                       // if not contains .webm
                       
                       // rewrite in future
                       NSMutableString *fullThumbPath = [[NSMutableString alloc] initWithString:DVACH_BASE_URL];
                       [fullThumbPath appendString:self.boardCode];
                       [fullThumbPath appendString:@"/"];
                       [fullThumbPath appendString:[files objectForKey:@"thumbnail"]];
                       thumbPathMut = fullThumbPath;
                       fullThumbPath = nil;
                       
                       // rewrite in future
                       NSMutableString *fullPicPath = [[NSMutableString alloc] initWithString:DVACH_BASE_URL];
                       [fullPicPath appendString:_boardCode];
                       [fullPicPath appendString:@"/"];
                       [fullPicPath appendString:[files objectForKey:@"path"]];
                       picPathMut = fullPicPath;
                       fullPicPath = nil;
                       
                       [_thumbImagesArray addObject:thumbPathMut];
                       [_fullImagesArray addObject:picPathMut];
                       
                   }
                   
               }
               else
               {
                   // if there are no files - make blank file paths
                   thumbPathMut = [[NSMutableString alloc] initWithString:@""];
                   picPathMut = [[NSMutableString alloc] initWithString:@""];
               }
               NSString *thumbPath = thumbPathMut;
               NSString *picPath = picPathMut;
               
               DVBPostObj *postObj = [[DVBPostObj alloc] initWithNum:num subject:subject comment:comment path:picPath thumbPath:thumbPath];
               [postsFullMutArray addObject:postObj];
               postObj = nil;
           }
           
           NSArray *resultArr = [[NSArray alloc] initWithArray:postsFullMutArray];
           
           [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
           
           completion(resultArr);
       }];
    }
    
}

// reload thread by current thread num
- (void)reloadThread {
    [self getPostsWithBoard:_boardCode
                  andThread:_threadNum
              andCompletion:^(NSArray *postsArrayBlock)
    {
        _postsArray = [postsArrayBlock mutableCopy];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
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
    CGPoint pointToScrollTo = CGPointMake(0, self.tableView.contentSize.height-self.tableView.frame.size.height);
    [self.tableView setContentOffset:pointToScrollTo animated:YES];
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
                
                DVBPostObj *post = [_postsArray objectAtIndex:self.selectedWithLongPressSection];
                
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
                        [self deletePostWithIndex:self.selectedWithLongPressSection fromMutableArray:self.postsArray];
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
             
             NSString *status = [resultDict objectForKey:@"status"];
             
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
{
    [array removeObjectAtIndex:index];
    BOOL threadOrNot = NO;
    if ((index == 0)&&(!_opAlreadyDeleted))
    {
        threadOrNot = YES;
        self.opAlreadyDeleted = YES;
    }
    DVBBadPost *tmpBadPost = [[DVBBadPost alloc] initWithNum:_flaggedPostNum
                                                 threadOrNot:threadOrNot];
    [_badPostsStorage.badPostsArray addObject:tmpBadPost];
    BOOL badPostsSavingSuccess = [_badPostsStorage saveChanges];
    if (badPostsSavingSuccess)
    {
        NSLog(@"Bad Posts saved to file");
    }
    else
    {
        NSLog(@"Couldn't save bad posts to file");
    }
    if (index == 0)
    {
        [self.delegate sendDataToBoard:self.threadIndex];
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
            [self deletePostWithIndex:_selectedWithLongPressSection fromMutableArray:_postsArray];
        }
    }];
}

#pragma mark - Photo gallery

// test touch on image method
- (void)handleTapOnImageViewWithIndexPath: (NSIndexPath *)indexPath
{
    [self createAndPushGalleryWithIndexPath:indexPath];
}

- (void)createAndPushGalleryWithIndexPath:(NSIndexPath *)indexPath
{
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    
    browser.displayActionButton = YES; // Show action button to allow sharing, copying, etc (defaults to YES)
    browser.displayNavArrows = YES; // Whether to display left and right nav arrows on toolbar (defaults to NO)
    browser.displaySelectionButtons = NO; // Whether selection buttons are shown on each image (defaults to NO)
    browser.zoomPhotosToFill = NO; // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
    browser.alwaysShowControls = NO; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
    browser.enableGrid = YES; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
    browser.startOnGrid = NO; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
    
    // Optionally set the current visible photo before displaying
    NSUInteger indexForImageShowing = indexPath.section;
    DVBPostObj *postObj = [_postsArray objectAtIndex:indexForImageShowing];
    NSString *path = postObj.path;
    NSUInteger index = [_fullImagesArray indexOfObject:path];
    [browser setCurrentPhotoIndex:index];
    
    // Present
    [self.navigationController pushViewController:browser animated:YES];
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser
{
    return [self.fullImagesArray count];
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser
                photoAtIndex:(NSUInteger)index
{
    
    if (index < _fullImagesArray.count)
    {
        MWPhoto *mwpPhoto = [MWPhoto photoWithURL:[NSURL URLWithString:[_fullImagesArray objectAtIndex:index]]];
        return mwpPhoto;
    }
    
    return nil;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index
{
    
    if (index < _thumbImagesArray.count)
    {
        MWPhoto *mwpPhoto = [MWPhoto photoWithURL:[NSURL URLWithString:[_thumbImagesArray objectAtIndex:index]]];
        return mwpPhoto;
    }
    
    return nil;
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
    CGPoint pointToScrollTo = CGPointMake(0, self.tableView.contentSize.height-self.tableView.frame.size.height);
    [self.tableView setContentOffset:pointToScrollTo animated:YES];
    
    NSLog(@"Table updated after posting.");
}

@end