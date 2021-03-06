//
//  Note.h
//  Beauteous
//
//  Created by Kenichi Saito on 7/29/15.
//  Copyright (c) 2015 Kenichi Saito. All rights reserved.
//

#import <Realm/Realm.h>

@interface Note : RLMObject

@property NSInteger id;
@property NSString *title;
@property NSString *planeString;
@property NSString *htmlString;
@property NSDate   *created_at;
@property NSDate   *updated_at;
@property BOOL     starred;
@property BOOL     deleted;
@property NSString *photoUrl;

@end
