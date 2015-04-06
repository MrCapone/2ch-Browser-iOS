//
//  DVBBoardsModel.m
//  dvach-browser
//
//  Created by Mega on 12/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>
#import "DVBBoardsModel.h"
#import "DVBBoardObj.h"

#import "DVBNetworking.h"
#import "DVBStatus.h"
#import "DVBValidation.h"
#import "DVBBoardTableViewCell.h"
#import "DVBConstants.h"

static NSString *const BOARD_STORAGE_FILE_PATH = @"store.data";
static NSString *const DVBBOARD_ENTITY_NAME = @"DVBBoardObj";
static NSString *const DEFAULT_BOARDS_PLIST_FILENAME = @"DefaultBoards";
static NSString *const BOARD_CATEGORIES_PLIST_FILENAME = @"BoardCategories";

@interface DVBBoardsModel ()

@property (nonatomic, strong) NSMutableArray *boardsPrivate;
// Core data properties.
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) NSManagedObjectModel *model;
// to not store boards gotten from network in DB
@property (nonatomic, strong) NSPersistentStore *memoryStore;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

@implementation DVBBoardsModel

#pragma mark - Init and Core Data

+ (instancetype)sharedBoardsModel {
    static DVBBoardsModel *sharedBoardsModel = nil;
    
    if (!sharedBoardsModel) {
        sharedBoardsModel = [[self alloc] initPrivate];
    }
    
    return sharedBoardsModel;
}

/**
 *  Not permitting to create multiple instances of DVBBoardsModel
 *
 *  @return always nil
 */
- (instancetype)init {
    @throw [NSException exceptionWithName:@"Singleton" reason:@"Use +[DVBBoardsModel sharedBoardsModel]" userInfo:nil];
    
    return nil;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        // Read from datamodel
        _model = [NSManagedObjectModel mergedModelFromBundles:nil];
        
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_model];
        
        // Get path for SQL file.
        NSString *boardsStorageFilePath = [self boardsArchivePath];
        NSURL *boardsStorageURL = [NSURL fileURLWithPath:boardsStorageFilePath];
        NSError *error = nil;
        
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                      configuration:nil
                                                                URL:boardsStorageURL
                                                            options:nil
                                                              error:&error])
        {
            @throw [NSException exceptionWithName:@"OpenFailure" reason:[error localizedDescription] userInfo:nil];
        }
        
        // Create the managed object context
        _context = [[NSManagedObjectContext alloc] init];
        _context.persistentStoreCoordinator = _persistentStoreCoordinator;
        _boardCategoriesArray = [self loadBoardCategoriesFromPlist];
        [self loadAllboards];
    }
    
    return self;
}

/**
 *  Determining path for loading/saving array of LTWords to disk
 *
 *  @return path of file to save to
 */
- (NSString *)boardsArchivePath {
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [documentDirectories firstObject];
    
    return [documentDirectory stringByAppendingPathComponent:BOARD_STORAGE_FILE_PATH];
}

- (BOOL)saveChanges {
    
    NSError *error;
    BOOL successful = [_context save:&error];
    
    if (!successful) {
        NSLog(@"Error saving: %@", [error localizedDescription]);
    }
    
    return successful;
}

/**
 *  Getter method for boardsArray.
 *
 *  @return Array of all boards in model.
 */
- (NSArray *)boardsArray {
    return _boardsPrivate;
}

- (void)loadAllboards {
    // To prevent from "rebuilding" it
    _memoryStore = [_persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:nil];
    
   // if (!_boardsPrivate) {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *wordEntityDescription = [NSEntityDescription entityForName:DVBBOARD_ENTITY_NAME inManagedObjectContext:_context];
        request.entity = wordEntityDescription;
        NSSortDescriptor *sortDescriptorByOrderKey = [NSSortDescriptor sortDescriptorWithKey:@"boardId" ascending:YES];
        request.sortDescriptors = @[sortDescriptorByOrderKey];
        NSError *error;
        NSArray *result = [_context executeFetchRequest:request error:&error];
        
        if (!result) {
            [NSException raise:@"Fetch failed" format:@"Reason: %@", [error localizedDescription]];
        }
        
        NSUInteger boardsCount = [result count];
        
        if (boardsCount) {
            // load from file
            _boardsPrivate = [[NSMutableArray alloc] initWithArray:result];
            [self checkBoardNames];
        }
        else {
            // create first time
            _boardsPrivate = [NSMutableArray array];
            [self loadBoardsFromPlist];
        }
        
   // }
}

- (void)addBoardWithBoardId:(NSString *)boardId andBoardName:(NSString *)name andCategoryId:(NSNumber *)categoryId {
    // Constructing DVBBoardObj with Core Data
    DVBBoardObj *board = [NSEntityDescription insertNewObjectForEntityForName:DVBBOARD_ENTITY_NAME inManagedObjectContext:_context];
    board.boardId = boardId;
    board.name = name;
    board.categoryId = categoryId;
    
    [_boardsPrivate addObject:board];
}

- (void)addBoardWithBoardId:(NSString *)boardId {
    // Constructing DVBBoardObj with Core Data
    DVBBoardObj *board = [NSEntityDescription insertNewObjectForEntityForName:DVBBOARD_ENTITY_NAME inManagedObjectContext:_context];
    board.boardId = boardId;
    board.name = @"";
    
    // because 0 - categoryId for favourite category
    NSNumber *favouriteCategoryId = [NSNumber numberWithInt:0];
    board.categoryId = favouriteCategoryId;
    [_boardsPrivate addObject:board];
    
    [self saveChanges];
    [self loadAllboards];
}

- (void)loadBoardsFromPlist {
    // Get default boards from plist
    NSArray *defaultBoardsArray =[NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:DEFAULT_BOARDS_PLIST_FILENAME ofType:@"plist"]];
    
    for (id board in defaultBoardsArray) {
        NSString *boardId = board[@"boardId"];
        NSString *boardName = board[@"name"];
        NSNumber *categoryId = board[@"categoryId"];
        
        [self addBoardWithBoardId:boardId
                     andBoardName:boardName
                    andCategoryId:categoryId];
    }

    [self saveChanges];
    [self loadAllboards];
}

- (NSArray *)loadBoardCategoriesFromPlist {
    // get category names from plist
    return [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:BOARD_CATEGORIES_PLIST_FILENAME ofType:@"plist"]];
}

- (void)getBoardsWithCompletion:(void (^)(NSArray *))completion {
    DVBNetworking *networkHandler = [[DVBNetworking alloc] init];
    [networkHandler getBoardsFromNetworkWithCompletion:^(NSDictionary *boardsDict) {
        NSMutableArray *boardsFromNetworkMutableArray = [NSMutableArray array];
        for (id key in boardsDict) {
            NSArray *boardsInsideCategory = [[NSArray alloc] initWithArray:[boardsDict objectForKey:key]];
            for (NSDictionary *singleBoardDictionary in boardsInsideCategory) {
                NSString *boardId = singleBoardDictionary[@"id"];
                NSString *name = singleBoardDictionary[@"name"];
                NSNumber *pages = singleBoardDictionary[@"pages"];
                
                DVBBoardObj *board = [NSEntityDescription insertNewObjectForEntityForName:DVBBOARD_ENTITY_NAME inManagedObjectContext:_context];
                [_context assignObject:board toPersistentStore:_memoryStore];
                board.boardId = boardId;
                board.name = name;
                board.pages = pages;
                
                [boardsFromNetworkMutableArray addObject:board];
                
                // we need to delete this temp created object or it will appear in table after realoading
                [_context deleteObject:board];
            }
        }
        NSArray *boardsFromNetworkArray = boardsFromNetworkMutableArray;
        completion(boardsFromNetworkArray);
    }];
};

- (void)checkBoardNames {
    BOOL isNeedToLoadBoardsFromNetwork = NO;
    for (DVBBoardObj *board in self.boardsArray) {
        NSString *name = board.name;
        BOOL isNameEmpty = [name isEqualToString:@""];
        if (isNameEmpty) {
            isNeedToLoadBoardsFromNetwork = YES;
            break;
        }
    }
    if (isNeedToLoadBoardsFromNetwork) {
        NSMutableArray *arrayForInterating = [self.boardsArray mutableCopy];
        [self getBoardsWithCompletion:^(NSArray *completion) {
            NSUInteger indexOfCurrentBoard = 0;
            for (DVBBoardObj *board in arrayForInterating) {
                NSString *name = board.name;
                NSString *boardId = board.boardId;
                BOOL isNameEmpty = [name isEqualToString:@""];
                if (isNameEmpty) {
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(boardId == %@)", boardId];
                    NSArray *matchedBoardsFromNetwork = [completion filteredArrayUsingPredicate:predicate];
                    NSUInteger matchedBoardsCount = [matchedBoardsFromNetwork count];
                    if (matchedBoardsCount > 0) {
                        DVBBoardObj *boardFromNetwork = matchedBoardsFromNetwork[0];
                        NSString *nameOfTheMatchedBoard = boardFromNetwork.name;
                        board.name = nameOfTheMatchedBoard;
                        [_boardsPrivate setObject:board atIndexedSubscript:indexOfCurrentBoard];
                    }
                }
                indexOfCurrentBoard++;
            }
            [self saveChanges];
            // [self loadAllboards];
            [_boardsModelDelegate updateTable];
        }];
    }
}

/*

- (NSString *)getBoardIdWithCategoryName:(NSString *)category
                                andIndex:(NSUInteger)index
{
    if (_boardsDictionaryByCategories)
    {
        DVBBoardObj *boardObject = _boardsDictionaryByCategories[category][index];
        NSString *boardId = boardObject.boardId;
        
        return boardId;
    }
    return @"";
}

- (NSUInteger)getBoardPagesWithBoardId:(NSString *)boardId
{
    NSPredicate *predicateByBoardId = [NSPredicate predicateWithFormat:@"boardId == %@", boardId];
    NSArray *filteredArrayOfBoardsForBoardId = [_boardsArray filteredArrayUsingPredicate:predicateByBoardId];
    
    if ([filteredArrayOfBoardsForBoardId count] > 0)
    {
        DVBBoardObj *boardObj = [filteredArrayOfBoardsForBoardId firstObject];
        NSUInteger pages = boardObj.pages;
        
        return pages;
    }
    return 0;
}
 */

#pragma mark - TableView delegate & DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_boardCategoriesArray count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *categoryTitle = _boardCategoriesArray[section];
    
    return categoryTitle;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self countOfBoardsInCategoryWithIndex:section];
}

- (DVBBoardTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DVBBoardTableViewCell *boardCell = [tableView dequeueReusableCellWithIdentifier:BOARD_CELL_IDENTIFIER];
    
    NSUInteger categoryIndex = indexPath.section;
    
    NSArray *boardsArrayInCategory = [self arrayForCategoryWithIndex:categoryIndex];
    
    DVBBoardObj *boardObject = boardsArrayInCategory[indexPath.row];
    
    [boardCell prepareCellWithBoardObject:boardObject];
    
    return boardCell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Permit editing only items of the Favourite section
    NSUInteger section = indexPath.section;
    if (section == 0) {
        return YES;
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        NSMutableArray *arrayForInterating = [_boardsPrivate mutableCopy];
        NSString *boardIdToDeleteFromFavourites = [self boardIdByIndexPath:indexPath];
        NSUInteger indexOfCurrentBoard = 0;
        for (DVBBoardObj *board in arrayForInterating) {
            NSString *boardId = board.boardId;
            NSNumber *boardCategoryId = board.categoryId;
            NSNumber *favouritesCategoryid = [NSNumber numberWithInt:0];
            BOOL isBoardIdEquals = [boardId isEqualToString:boardIdToDeleteFromFavourites];
            BOOL isInFavourites = ([boardCategoryId intValue] == [favouritesCategoryid intValue]);
            if (isBoardIdEquals && isInFavourites) {
                [_boardsPrivate removeObjectAtIndex:indexOfCurrentBoard];
                [_context deleteObject:board];
                break;
            }
            indexOfCurrentBoard++;
        }
        [self saveChanges];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
        // [self loadAllboards];
        // [_boardsModelDelegate updateTable];
    }
}



- (NSString *)boardIdByIndexPath:(NSIndexPath *)indexPath {
    
    NSArray *boardsInThecategoryArray = [self arrayForCategoryWithIndex:indexPath.section];
    DVBBoardObj *board = boardsInThecategoryArray[indexPath.row];
    NSString *boardId = board.boardId;
    
    return boardId;
}

#pragma mark - Table helpers

- (NSArray *)arrayForCategoryWithIndex:(NSUInteger)index {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(categoryId == %ld)", index];
    NSArray *matchedBoardsResult = [self.boardsArray filteredArrayUsingPredicate:predicate];
    
    return matchedBoardsResult;
}

- (NSUInteger)countOfBoardsInCategoryWithIndex:(NSUInteger)index {
    
    NSArray *matchedBoardsResult = [self arrayForCategoryWithIndex:index];
    
    return [matchedBoardsResult count];
}

@end