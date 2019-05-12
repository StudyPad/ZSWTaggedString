//
//  ZSWTaggedStringOptionsSpec.m
//  ZSWTaggedString
//
//  Created by Zachary West on 2015-02-22.
//  Copyright (c) 2015 Zachary West. All rights reserved.
//

@import ZSWTaggedString.Private;

SpecBegin(ZSWTaggedStringOptions)

describe(@"ZSWTaggedStringOptions", ^{
    beforeEach(^{
        // reset global state
        [ZSWTaggedStringOptions registerDefaultOptions:[ZSWTaggedStringOptions options]];
    });
    
    describe(@"default options", ^{
        it(@"should return an empty options by default", ^{
            ZSWTaggedStringOptions *options = [ZSWTaggedStringOptions defaultOptions];
            expect(options.baseAttributes).to.haveCountOf(0);
            expect(options._private_tagToAttributesMap).to.haveCountOf(0);
        });
        
        it(@"should return copy of the options each time", ^{
            expect([ZSWTaggedStringOptions defaultOptions]).to.equal([ZSWTaggedStringOptions defaultOptions]);
            expect([ZSWTaggedStringOptions defaultOptions]).toNot.beIdenticalTo([ZSWTaggedStringOptions defaultOptions]);
        });
        
        describe(@"when registering defaults", ^{
            __block ZSWTaggedStringOptions *options;
            
            beforeEach(^{
                options = [ZSWTaggedStringOptions options];
            });
            
            it(@"should return an equal instance that isn't the same", ^{
                expect([ZSWTaggedStringOptions defaultOptions]).to.equal(options);
                expect([ZSWTaggedStringOptions defaultOptions]).toNot.beIdenticalTo(options);
            });
            
            describe(@"when mutated after registration", ^{
                beforeEach(^{
                    options.baseAttributes = @{ NSForegroundColorAttributeName: [UIColor redColor] };
                });
                
                it(@"should not modify the default options", ^{
                    expect([ZSWTaggedStringOptions defaultOptions]).toNot.equal(options);
                });
            });
        });
    });
    
    sharedExamples(@"a happy options", ^(NSDictionary *data) {
        __block ZSWTaggedStringOptions *options;
        
        beforeEach(^{
            options = data[@"o"];
        });
        
        describe(@"when copied", ^{
            __block ZSWTaggedString *copiedOptions;
            
            beforeEach(^{
                copiedOptions = [options copy];
            });
            
            it(@"should compare equal", ^{
                expect(copiedOptions).to.equal(options);
                expect(copiedOptions.hash).to.equal(options.hash);
            });
        });
    });
    
    describe(@"options with everything set", ^{
        __block ZSWTaggedStringOptions *options;
        
        beforeEach(^{
            options = [[ZSWTaggedStringOptions alloc] init];
            
            options.baseAttributes = @{ @"b": @"c" };
            [options setAttributes:@{ @"d": @"a" } forTagName:@"abc"];
            [options setDynamicAttributes:^NSDictionary<NSAttributedStringKey,id> * _Nonnull(NSString * _Nonnull tagName, NSDictionary<NSString *,id> * _Nonnull tagAttributes, NSDictionary<NSAttributedStringKey,id> * _Nonnull existingStringAttributes) {
                return @{ @"c": @"d" };
            } forTagName:@"xyz"];
            [options setUnknownTagDynamicAttributes:^NSDictionary *(NSString *tagName, NSDictionary *tagAttributes, NSDictionary *existingAttributes) {
                return @{ @"q": @"z" };
            }];
        });
        
        itShouldBehaveLike(@"a happy options", ^{
            return @{ @"o": options };
        });
    });
    
    describe(@"when handling overlapping tags", ^{
        // We use the following string for these examples:
        //
        // "<s1>Did you <comeknock>come <knock>knocking</knock></comeknock> on my door?</s1> <s2>Or <dict>did <i>I</i> come to yours</dict></s2>"
        //
        //                       0         1         2         3         4         5
        //                       0123456789012345678901234567890123456789012345678901234567890
        NSString *baseString = @"Did you come knocking on my door? Or did I come to yours?";
        //                       ^       ^    ^      |           | ^  ^   ^              |
        //                       |       |    knock  |           | |  |   i              |
        //                       |       comeknock ---           | |  dict----------------
        //                       s1 ------------------------------ s2 --------------------
        
        struct {
            NSInteger start, end;
        } p_whole = {0, 57}, p_s1 = {0, 33}, p_s2 = {34, 57}, p_comeknock = {8, 21}, p_knock = {13, 21}, p_dict = {37, 57}, p_i = {41, 42};
        
        ZSWStringParserTag *s1 = [[ZSWStringParserTag alloc] initWithTagName:@"s1" startLocation:p_s1.start];
        [s1 updateWithTag:[[ZSWStringParserTag alloc] initWithTagName:@"/s1" startLocation:p_s1.end]];
        
        ZSWStringParserTag *comeknock = [[ZSWStringParserTag alloc] initWithTagName:@"comeknock" startLocation:p_comeknock.start];
        [comeknock updateWithTag:[[ZSWStringParserTag alloc] initWithTagName:@"/comeknock" startLocation:p_comeknock.end]];
        
        ZSWStringParserTag *knock = [[ZSWStringParserTag alloc] initWithTagName:@"knock" startLocation:p_knock.start];
        [knock updateWithTag:[[ZSWStringParserTag alloc] initWithTagName:@"/knock" startLocation:p_knock.end]];
        
        ZSWStringParserTag *s2 = [[ZSWStringParserTag alloc] initWithTagName:@"s2" startLocation:p_s2.start];
        [s2 updateWithTag:[[ZSWStringParserTag alloc] initWithTagName:@"/s2" startLocation:p_s2.end]];
        
        ZSWStringParserTag *dict = [[ZSWStringParserTag alloc] initWithTagName:@"dict" startLocation:p_dict.start];
        [dict updateWithTag:[[ZSWStringParserTag alloc] initWithTagName:@"/dict" startLocation:p_dict.end]];
        
        ZSWStringParserTag *i = [[ZSWStringParserTag alloc] initWithTagName:@"i" startLocation:p_i.start];
        [i updateWithTag:[[ZSWStringParserTag alloc] initWithTagName:@"/i" startLocation:p_i.end]];
        
        NSArray *tags = @[ s1, comeknock, knock, s2, dict, i ];
        
        __block NSMutableAttributedString *string;
        
        beforeEach(^{
            string = [[NSMutableAttributedString alloc] initWithString:baseString attributes:nil];
        });
        
        describe(@"when creating a string with base attributes only", ^{
            __block ZSWTaggedStringOptions *options;
            
            beforeEach(^{
                NSDictionary *baseAttributes = @{ NSForegroundColorAttributeName: [UIColor redColor],
                                                  NSFontAttributeName: [UIFont systemFontOfSize:12.0] };
                options = [ZSWTaggedStringOptions optionsWithBaseAttributes:baseAttributes];
            });
            
            it(@"should produce a string with attributes across the whole thing", ^{
                [options _private_updateAttributedString:string updatedWithTags:tags];
                expect(string.string).to.equal(baseString);
                expect(string).to.haveAttributeWithEnd(NSForegroundColorAttributeName, [UIColor redColor], p_whole.start, p_whole.end);
                expect(string).to.haveAttributeWithEnd(NSFontAttributeName, [UIFont systemFontOfSize:12.0], p_whole.start, p_whole.end);
            });
            
            itShouldBehaveLike(@"a happy options", ^{
                return @{ @"o": options };
            });
        });
        
        describe(@"when creating a string with non-overlapping tags", ^{
            __block ZSWTaggedStringOptions *options;
            
            beforeEach(^{
                NSDictionary *baseAttributes = @{ NSForegroundColorAttributeName: [UIColor orangeColor],
                                                  NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle) };
                options = [ZSWTaggedStringOptions optionsWithBaseAttributes:baseAttributes];
                
                [options setAttributes:@{ NSForegroundColorAttributeName: [UIColor greenColor] } forTagName:@"s1"];
                [options setAttributes:@{ NSForegroundColorAttributeName: [UIColor blueColor] } forTagName:@"s2"];
            });
            
            itShouldBehaveLike(@"a happy options", ^{
                return @{ @"o": options };
            });
            
            it(@"should produce the right string", ^{
                [options _private_updateAttributedString:string updatedWithTags:tags];
                expect(string.string).to.equal(baseString);
                
                expect(string).to.haveAttributeWithEnd(NSForegroundColorAttributeName, [UIColor greenColor], p_s1.start, p_s1.end);
                expect(string).to.haveAttributeWithEnd(NSForegroundColorAttributeName, [UIColor orangeColor], p_s1.end, p_s2.start);
                expect(string).to.haveAttributeWithEnd(NSForegroundColorAttributeName, [UIColor blueColor], p_s2.start, p_s2.end);
                expect(string).to.haveAttributeWithEnd(NSUnderlineStyleAttributeName, @(NSUnderlineStyleSingle), p_whole.start, p_whole.end);
            });
        });
        
        describe(@"when creating a string with overlapping tags but no unhandled tag handler", ^{
            __block ZSWTaggedStringOptions *options;
            
            beforeEach(^{
                NSDictionary *baseAttributes = @{ NSForegroundColorAttributeName: [UIColor orangeColor],
                                                  NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle) };
                options = [ZSWTaggedStringOptions optionsWithBaseAttributes:baseAttributes];
                
                [options setAttributes:@{ NSForegroundColorAttributeName: [UIColor blackColor] } forTagName:@"s1"];
                [options setAttributes:@{ NSForegroundColorAttributeName: [UIColor blueColor] } forTagName:@"s2"];
                [options setAttributes:@{ NSForegroundColorAttributeName: [UIColor redColor] } forTagName:@"knock"];
                [options setAttributes:@{ NSForegroundColorAttributeName: [UIColor purpleColor] } forTagName:@"dict"];
                
                [options setDynamicAttributes:^(NSString *tagName, NSDictionary *tagAttributes, NSDictionary *existingAttributes) {
                    return @{ NSForegroundColorAttributeName: [UIColor greenColor],
                              NSStrikethroughStyleAttributeName: @(NSUnderlineStyleSingle) };
                } forTagName:@"comeknock"];
                
                [options setDynamicAttributes:^(NSString *tagName, NSDictionary *tagAttributes, NSDictionary *existingAttributes) {
                    return @{ NSForegroundColorAttributeName: [UIColor grayColor],
                              NSUnderlineStyleAttributeName: @(NSUnderlineStyleDouble) };
                } forTagName:@"i"];
            });
            
            itShouldBehaveLike(@"a happy options", ^{
                return @{ @"o": options };
            });
            
            it(@"should produce the right string", ^{
                [options _private_updateAttributedString:string updatedWithTags:tags];
                expect(string.string).to.equal(baseString);
                
                // the only global space left
                expect(string).to.haveAttributeWithEnd(NSForegroundColorAttributeName, [UIColor orangeColor], p_s1.end, p_s2.start);
                
                // non-i global
                expect(string).to.haveAttributeWithEnd(NSUnderlineStyleAttributeName, @(NSUnderlineStyleSingle), p_whole.start, p_i.start);
                expect(string).to.haveAttributeWithEnd(NSUnderlineStyleAttributeName, @(NSUnderlineStyleSingle), p_i.end, p_whole.end);
                
                // only non-covered s1
                expect(string).to.haveAttributeWithEnd(NSForegroundColorAttributeName, [UIColor blackColor], p_s1.start, p_comeknock.start);
                expect(string).to.haveAttributeWithEnd(NSForegroundColorAttributeName, [UIColor blackColor], p_knock.end, p_s1.end);
                
                // only non-covered comeknock
                expect(string).to.haveAttributeWithEnd(NSForegroundColorAttributeName, [UIColor greenColor], p_comeknock.start, p_knock.start);
                // all of comeknock
                expect(string).to.haveAttributeWithEnd(NSStrikethroughStyleAttributeName, @(NSUnderlineStyleSingle), p_comeknock.start, p_comeknock.end);
                
                // knock
                expect(string).to.haveAttributeWithEnd(NSForegroundColorAttributeName, [UIColor redColor], p_knock.start, p_knock.end);
                
                // only non-covered s2
                expect(string).to.haveAttributeWithEnd(NSForegroundColorAttributeName, [UIColor blueColor], p_s2.start, p_dict.start);
                
                // only non-covered dict
                expect(string).to.haveAttributeWithEnd(NSForegroundColorAttributeName, [UIColor purpleColor], p_dict.start, p_i.start);
                expect(string).to.haveAttributeWithEnd(NSForegroundColorAttributeName, [UIColor purpleColor], p_i.end, p_s2.end);
                
                // i
                expect(string).to.haveAttributeWithEnd(NSForegroundColorAttributeName, [UIColor grayColor], p_i.start, p_i.end);
                expect(string).to.haveAttributeWithEnd(NSUnderlineStyleAttributeName, @(NSUnderlineStyleDouble), p_i.start, p_i.end);
            });
        });
        
        describe(@"when creating a string with overlapping tags while using the dynamic tag handler", ^{
            __block ZSWTaggedStringOptions *options;
            
            beforeEach(^{
                NSDictionary *baseAttributes = @{ NSForegroundColorAttributeName: [UIColor orangeColor],
                                                  NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle) };
                options = [ZSWTaggedStringOptions optionsWithBaseAttributes:baseAttributes];
                
                
                [options setAttributes:@{ NSForegroundColorAttributeName: [UIColor blackColor] } forTagName:@"s1"];
                [options setAttributes:@{ NSForegroundColorAttributeName: [UIColor blueColor] } forTagName:@"s2"];
                
                [options setUnknownTagDynamicAttributes:^NSDictionary *(NSString *tagName, NSDictionary *tagAttributes, NSDictionary *existingAttributes) {
                    if ([tagName isEqualToString:@"comeknock"]) {
                        return @{ NSForegroundColorAttributeName: [UIColor greenColor],
                                  NSStrikethroughStyleAttributeName: @(NSUnderlineStyleSingle) };
                    } else if ([tagName isEqualToString:@"knock"]) {
                        return @{ NSForegroundColorAttributeName: [UIColor redColor] };
                    } else if ([tagName isEqualToString:@"dict"]) {
                        return @{ NSForegroundColorAttributeName: [UIColor purpleColor] };
                    } else if ([tagName isEqualToString:@"i"]) {
                        return @{ NSForegroundColorAttributeName: [UIColor grayColor],
                                  NSUnderlineStyleAttributeName: @(NSUnderlineStyleDouble) };
                    } else {
                        return nil;
                    }
                }];
            });
            
            itShouldBehaveLike(@"a happy options", ^{
                return @{ @"o": options };
            });
            
            it(@"should produce the right string", ^{
                [options _private_updateAttributedString:string updatedWithTags:tags];
                expect(string.string).to.equal(baseString);
                
                // the only global space left
                expect(string).to.haveAttributeWithEnd(NSForegroundColorAttributeName, [UIColor orangeColor], p_s1.end, p_s2.start);
                
                // non-i global
                expect(string).to.haveAttributeWithEnd(NSUnderlineStyleAttributeName, @(NSUnderlineStyleSingle), p_whole.start, p_i.start);
                expect(string).to.haveAttributeWithEnd(NSUnderlineStyleAttributeName, @(NSUnderlineStyleSingle), p_i.end, p_whole.end);
                
                // only non-covered s1
                expect(string).to.haveAttributeWithEnd(NSForegroundColorAttributeName, [UIColor blackColor], p_s1.start, p_comeknock.start);
                expect(string).to.haveAttributeWithEnd(NSForegroundColorAttributeName, [UIColor blackColor], p_knock.end, p_s1.end);
                
                // only non-covered comeknock
                expect(string).to.haveAttributeWithEnd(NSForegroundColorAttributeName, [UIColor greenColor], p_comeknock.start, p_knock.start);
                // all of comeknock
                expect(string).to.haveAttributeWithEnd(NSStrikethroughStyleAttributeName, @(NSUnderlineStyleSingle), p_comeknock.start, p_comeknock.end);
                
                // knock
                expect(string).to.haveAttributeWithEnd(NSForegroundColorAttributeName, [UIColor redColor], p_knock.start, p_knock.end);
                
                // only non-covered s2
                expect(string).to.haveAttributeWithEnd(NSForegroundColorAttributeName, [UIColor blueColor], p_s2.start, p_dict.start);
                
                // only non-covered dict
                expect(string).to.haveAttributeWithEnd(NSForegroundColorAttributeName, [UIColor purpleColor], p_dict.start, p_i.start);
                expect(string).to.haveAttributeWithEnd(NSForegroundColorAttributeName, [UIColor purpleColor], p_i.end, p_s2.end);
                
                // i
                expect(string).to.haveAttributeWithEnd(NSForegroundColorAttributeName, [UIColor grayColor], p_i.start, p_i.end);
                expect(string).to.haveAttributeWithEnd(NSUnderlineStyleAttributeName, @(NSUnderlineStyleDouble), p_i.start, p_i.end);
            });
        });
    });
    
    it(@"should handle empty-length tags", ^{
        ZSWTaggedStringOptions *options = [ZSWTaggedStringOptions options];
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"santa claus" attributes:nil];
        ZSWStringParserTag *unreferencedTag = [[ZSWStringParserTag alloc] initWithTagName:@"null" startLocation:1];
        [unreferencedTag updateWithTag:[[ZSWStringParserTag alloc] initWithTagName:@"/null" startLocation:1]];
        
        [options setAttributes:@{ NSForegroundColorAttributeName: [UIColor redColor] } forTagName:@"null"];

        [options _private_updateAttributedString:string updatedWithTags:@[ unreferencedTag ]];
        
        expect(string).to.equal([[NSAttributedString alloc] initWithString:@"santa claus" attributes:nil]);
    });

    it(@"should handle empty string after tags are removed", ^{
        // effectively this is "<blah><null></null></blah>"
        ZSWTaggedStringOptions *options = [ZSWTaggedStringOptions optionsWithBaseAttributes:@{
                                                                                              NSFontAttributeName: [UIFont systemFontOfSize:12.0]
                                                                                              }];
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"" attributes:nil];
        ZSWStringParserTag *tag1 = [[ZSWStringParserTag alloc] initWithTagName:@"null" startLocation:0];
        [tag1 updateWithTag:[[ZSWStringParserTag alloc] initWithTagName:@"/null" startLocation:0]];

        ZSWStringParserTag *tag2 = [[ZSWStringParserTag alloc] initWithTagName:@"blah" startLocation:0];
        [tag2 updateWithTag:[[ZSWStringParserTag alloc] initWithTagName:@"/blah" startLocation:0]];
        
        [options setDynamicAttributes:^NSDictionary<NSAttributedStringKey,id> * _Nonnull(NSString * _Nonnull tagName, NSDictionary<NSString *,id> * _Nonnull tagAttributes, NSDictionary<NSAttributedStringKey,id> * _Nonnull existingStringAttributes) {
            return @{ NSForegroundColorAttributeName: [UIColor redColor] };
        } forTagName:@"null"];
        
        [options setAttributes:@{ NSForegroundColorAttributeName: [UIColor redColor] }
                    forTagName:@"blah"];
        
        [options _private_updateAttributedString:string updatedWithTags:@[ tag1, tag2 ]];
        
        expect(string).to.equal([[NSAttributedString alloc] initWithString:@"" attributes:nil]);

    });
    
    describe(@"when a string contains multiple of the same type", ^{
        __block ZSWTaggedStringOptions *options;
        __block NSMutableAttributedString *string;
        __block NSArray *tags;
        
        beforeEach(^{
            options = [ZSWTaggedStringOptions options];
            
            string = [[NSMutableAttributedString alloc] initWithString:@"normalbob girthybob" attributes:nil];
            ZSWStringParserTag *normalbob = [[ZSWStringParserTag alloc] initWithTagName:@"bob" startLocation:0];
            [normalbob updateWithTag:[[ZSWStringParserTag alloc] initWithTagName:@"/bob" startLocation:9]];
            [normalbob addRawTagAttributes:@"type=normal"];
            
            ZSWStringParserTag *girthybob = [[ZSWStringParserTag alloc] initWithTagName:@"bob" startLocation:10];
            [girthybob updateWithTag:[[ZSWStringParserTag alloc] initWithTagName:@"/bob" startLocation:19]];
            [girthybob addRawTagAttributes:@"type=girthy"];
            
            tags = @[ normalbob, girthybob ];
        });
        
        itShouldBehaveLike(@"a happy options", ^{
            return @{ @"o": options };
        });
        
        it(@"should differentiate between the bob types where both have things", ^{
            [options setDynamicAttributes:^(NSString *tagName, NSDictionary *tagAttributes, NSDictionary *existingAttributes) {
                if ([tagAttributes[@"type"] isEqualToString:@"girthy"]) {
                    return @{ NSFontAttributeName: [UIFont boldSystemFontOfSize:14.0] };
                } else {
                    return @{ NSFontAttributeName: [UIFont systemFontOfSize:14.0] };
                }
            } forTagName:@"bob"];
            
            [options _private_updateAttributedString:string updatedWithTags:tags];
            
            expect(string).to.haveAttributeWithEnd(NSFontAttributeName, [UIFont systemFontOfSize:14.0], 0, 9);
            expect(string).to.haveAttributeWithEnd(NSFontAttributeName, nil, 9, 10);
            expect(string).to.haveAttributeWithEnd(NSFontAttributeName, [UIFont boldSystemFontOfSize:14.0], 10, 19);
        });
        
        it(@"should differentiate between the bob types where only one has things", ^{
            [options setDynamicAttributes:^NSDictionary *(NSString *tagName, NSDictionary *tagAttributes, NSDictionary *existingAttributes) {
                if ([tagAttributes[@"type"] isEqualToString:@"girthy"]) {
                    return @{ NSFontAttributeName: [UIFont boldSystemFontOfSize:14.0] };
                } else {
                    return nil;
                }
            } forTagName:@"bob"];
            
            [options _private_updateAttributedString:string updatedWithTags:tags];
            
            expect(string).to.haveAttributeWithEnd(NSFontAttributeName, nil, 0, 10);
            expect(string).to.haveAttributeWithEnd(NSFontAttributeName, [UIFont boldSystemFontOfSize:14.0], 10, 19);
        });
    });
});

SpecEnd
