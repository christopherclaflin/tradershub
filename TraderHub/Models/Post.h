//
//  Post.h
//  TraderHub
//
//  Created by imac on 1/3/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Post : NSObject {
    @public NSString *name;
    @public NSString *market;
    @public double  entry;
    @public double  stop;
    @public double  target;
    @public NSString *type;
}
@end
