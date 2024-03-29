//
//  GameScene.m
//  volleyball
//
//  Created by JASON HARRIS on 11/3/15.
//  Copyright (c) 2015 Jason Harris. All rights reserved.
//

#import "GameScene.h"
#import "GameAndScoreDetails.h"

@interface GameScene () <SKPhysicsContactDelegate, MultiplayerViewControllerDelegate>

//NODES AND SPRITES
@property (nonatomic, strong) SKShapeNode *showsTouchPoint;
@property (nonatomic, strong) SKSpriteNode *volleyBall;
@property (nonatomic, strong) SKNode *groundNodeLeft;
@property (nonatomic, strong) SKNode *groundNodeRight;
@property (nonatomic, strong) SKNode *wallNodeOne;
@property (nonatomic, strong) SKNode *wallNodeTwo;
@property (nonatomic, strong) SKLabelNode *scoreLabelNode;
@property (nonatomic, strong) SKLabelNode *restartButton;

//TRACKING VALUES
@property (nonatomic, assign) bool gameInPlay; //GAME IN PLAY
@property (nonatomic, assign) bool isMultiplayer;
@property (nonatomic, assign) bool lastTapper;
@property (nonatomic, assign) bool gameStopped; //GAME STOPPED
@property (nonatomic, assign) bool readyToRestart; //READY TO RESTART
//@property (nonatomic, assign) bool allowReceivingData;

@property (nonatomic, assign) CGFloat screenSizeMultiplier;
@property (nonatomic, assign) NSUInteger hostValue;
@property (nonatomic, strong) NSString *gameScore;
@property (nonatomic, strong) GameAndScoreDetails *localGameStore;
@property (nonatomic, assign) NSUInteger allowableHits;

//SETTINGS
@property (nonatomic, assign) CGFloat ballDepthInSand;
@property (nonatomic, assign) CGFloat gravityValue;
@property (nonatomic, assign) NSUInteger frameCounter;
@property (nonatomic, strong) SKColor *skyColor;

@end


@implementation GameScene

// scene categories
static const uint32_t ballCategory = 1 << 0;
static const uint32_t fenceCategory = 1 << 1;
static const uint32_t worldCategory = 1 << 2;
static const uint32_t floorCategoryLeft = 1 << 3;
static const uint32_t floorCategoryRight = 1 << 4;
static const uint32_t ceilingCategory = 1 << 5;
// scene categories


-(void)didMoveToView:(SKView *)view {
    /* Setup your scene here */
    self.physicsWorld.contactDelegate = self;
    self.screenSizeMultiplier = (1-self.view.frame.size.width / self.view.frame.size.height * 375 / 667.0);
    self.skyColor = [SKColor colorWithRed:112/255.0 green:200/255.0 blue:230/255.0 alpha:1.0];
//    self.skyColor = [SKColor blackColor]; //black color for troubleshooting
    self.ballDepthInSand = 10.0;
    self.gravityValue = -2.5;
    self.allowableHits = 4;
//    self.allowReceivingData = YES;
    self.lastTapper = NO;
    self.frameCounter = 0;
    self.hostValue = [GameAndScoreDetails sharedGameDataStore].host;
    self.localGameStore = [GameAndScoreDetails sharedGameDataStore];
    [self setBackgroundColor:self.skyColor];
    self.isMultiplayer = (self.hostValue == 0 || self.hostValue == 1);
    
    if (self.isMultiplayer)
    {
        self.multiPlayerVC.delegate = self;
    }
    
    
    [self setupSceneAndNodes];
    
    
    NSLog(@"%1.f width %1.f height self.frame",self.frame.size.width,self.frame.size.height);
    NSLog(@"%1.f width %1.f height self.view",self.view.frame.size.width,self.view.frame.size.height);
    NSLog(@"%1.f width %1.f height view.bounds",view.bounds.size.width,view.bounds.size.height);
    
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    
    if (self.lastTapper && self.frameCounter >3)
    {
        CGVector ballVector = self.volleyBall.physicsBody.velocity;
        [self sendDataToPlayer:ballVector location:self.volleyBall.position updateOrTap:@"update" dataSendMode:MCSessionSendDataUnreliable];
        self.frameCounter = 0;
    }
    
    self.frameCounter ++;
}




-(void)setupSceneAndNodes
{
    [self removeAllChildren];
    self.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
    self.readyToRestart = NO;
    self.gameStopped = NO;
    
    // SCORE LABEL SETUP
    self.scoreLabelNode = [SKLabelNode labelNodeWithFontNamed:@"ChalkboardSE-Bold"]; //http://iosfonts.com/
    self.scoreLabelNode.position = CGPointMake(self.frame.size.width/2,self.frame.size.height - 65);
    self.scoreLabelNode.position = CGPointMake(self.frame.size.width/2,120);
    self.scoreLabelNode.zPosition = 100;
    self.scoreLabelNode.name = @"scoreLabelNode";
    self.scoreLabelNode.fontColor = [SKColor blackColor];
    self.scoreLabelNode.fontSize = 65;
    [self updateScoreLabelNode];
    [self addChild:self.scoreLabelNode];
    
    
    //the touch point
    self.showsTouchPoint = [[SKShapeNode alloc] init];
    CGMutablePathRef ballPath = CGPathCreateMutable();
    CGPathAddArc(ballPath, NULL, 0,0, 15, 0, M_PI*2, YES);
    self.showsTouchPoint.path = ballPath;
    self.showsTouchPoint.lineWidth = 1.0;
    self.showsTouchPoint.fillColor = [SKColor darkGrayColor];
    self.showsTouchPoint.alpha = 0.5;
    self.showsTouchPoint.glowWidth = 0.0;
    self.showsTouchPoint.zPosition = 15;
    
    // volleyball
    SKTexture *volleyballTexture = [SKTexture textureWithImageNamed:@"Volleyball"];
    volleyballTexture.filteringMode = SKTextureFilteringNearest;
    
    self.volleyBall = [SKSpriteNode spriteNodeWithTexture:volleyballTexture];
    self.volleyBall.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:self.volleyBall.size.height/2];
    self.volleyBall.physicsBody.allowsRotation = YES;
    self.volleyBall.physicsBody.dynamic = YES;
    self.volleyBall.physicsBody.accessibilityLabel = @"volleyBall";
    self.volleyBall.physicsBody.categoryBitMask = ballCategory;
    self.volleyBall.physicsBody.collisionBitMask = fenceCategory | worldCategory | ceilingCategory | floorCategoryLeft | floorCategoryRight; // bounces off
    self.volleyBall.physicsBody.contactTestBitMask = fenceCategory | floorCategoryLeft; // notifications when collisions
    self.volleyBall.zPosition = 10;
    
    if ([GameAndScoreDetails sharedGameDataStore].theBallServer == LeftPlayerServe)
    {
       self.volleyBall.position = CGPointMake(self.size.width*1/6, self.size.height*3/5);
    } else {
       self.volleyBall.position = CGPointMake(self.size.width*5/6, self.size.height*3/5);
    }
    
    
    [self addChild:self.volleyBall];
    
    //wall one set up
    self.wallNodeOne = [SKNode node];
    self.wallNodeOne.position = CGPointMake(0, 0);
    self.wallNodeOne.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(1, self.frame.size.height*10)];
    self.wallNodeOne.physicsBody.categoryBitMask = worldCategory;
    self.wallNodeOne.physicsBody.dynamic = NO;
    [self addChild:self.wallNodeOne];
    
    //wall two set up
    self.wallNodeTwo = [SKNode node];
    self.wallNodeTwo.position = CGPointMake(self.frame.size.width, 0);
    self.wallNodeTwo.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(1, self.frame.size.height*10)];
    self.wallNodeTwo.physicsBody.categoryBitMask = worldCategory;
    self.wallNodeTwo.physicsBody.dynamic = NO;
    [self addChild:self.wallNodeTwo];
    
    
    //CEILING SET UP
    SKNode *ceiling = [SKNode node];
    ceiling.position = CGPointMake(0, self.frame.size.height*2);
    ceiling.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(self.frame.size.width * 10, 1)];
    ceiling.physicsBody.categoryBitMask = ceilingCategory;
    ceiling.physicsBody.dynamic = NO;
    ceiling.physicsBody.allowsRotation = NO;
    [self addChild:ceiling];
    
    
    //fence texture - this is all BS, using an arbitrary texture and height is all fudged
    SKTexture *fenceTexture = [SKTexture textureWithImageNamed:@"yellow+dot+med"];
    fenceTexture.filteringMode = SKTextureFilteringNearest;
    
    for(NSUInteger i = 0 ; i < 2 + self.frame.size.height/(fenceTexture.size.height*2)-2; i++)
    {
        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithTexture:fenceTexture];
        sprite.position = CGPointMake(self.frame.size.width / 2, (sprite.size.height)*i - 5); // subtraction places yellow balls closer together
        [self addChild:sprite];
    }
    
    //fence node setup - this seems to be alright
    SKNode *fenceNode = [SKNode node];
    fenceNode.position = CGPointMake(self.frame.size.width/2 , 0); // NODE POSITION
    fenceNode.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(20, self.frame.size.height/2) center:(CGPointMake(0, self.frame.size.height/4))]; //where to center this IN THE NODE
    fenceNode.physicsBody.categoryBitMask = fenceCategory;
    fenceNode.physicsBody.contactTestBitMask = ballCategory;
    fenceNode.physicsBody.dynamic = NO;
    fenceNode.physicsBody.allowsRotation = NO;
    [self addChild:fenceNode];
    
    //SET UP GROUND METHOD
    [self setUpGround];
    
    self.gameInPlay = NO;
    
}

-(void)placeRestartGameButton
{
    self.gameStopped = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.restartButton = [SKLabelNode labelNodeWithFontNamed:@"ChalkboardSE-Bold"]; //http://iosfonts.com/
        self.restartButton.position = CGPointMake(self.frame.size.width/2,self.frame.size.height/2);
        self.restartButton.zPosition = 100;
        self.restartButton.text = [NSString stringWithFormat:@"TAP TO RESET SERVE"];
        self.restartButton.name = @"resetGameNode";
        self.restartButton.fontColor = [SKColor blackColor];
        self.restartButton.fontSize = 80;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if((self.hostValue == self.localGameStore.theBallServer) || self.hostValue == 2)
            {
                self.readyToRestart = YES;
            }
            
        });
        [self addChild:self.restartButton];
    });
}

-(void)updateScoreLabelNode
{
    self.scoreLabelNode.text = [NSString stringWithFormat:@"%lu     -     %lu",(unsigned long)[GameAndScoreDetails sharedGameDataStore].leftPlayerScore,(unsigned long)[GameAndScoreDetails sharedGameDataStore].rightPlayerScore];
    
    
}


#pragma mark - set up ground stuff

-(void)setUpGround
{
    //ground set up
    SKTexture *groundTexture = [SKTexture textureWithImageNamed:@"Ground"];
    //    groundTexture.filteringMode = SKTextureFilteringNearest;
    CGFloat resultantHeight = 0;
    for(NSUInteger i = 0 ; i < 2 + self.frame.size.width/(groundTexture.size.width*2); i++)
    {
        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithTexture:groundTexture];
        [sprite setScale:2.0]; //CHECK THIS OUT
        sprite.position = CGPointMake(i*sprite.size.width, sprite.size.height / 2 + groundTexture.size.height * 2 - (self.screenSizeMultiplier* self.view.frame.size.height)); //CHECK THIS OUT
        sprite.zPosition = 5;
        resultantHeight = sprite.position.y;
        [self addChild:sprite];
    }
    
    //ground physics bodies set up
    
    self.groundNodeLeft = [SKNode node];
    self.groundNodeLeft.position = CGPointMake(self.frame.size.width / 4, resultantHeight - 10 ); // CENTERS ONE QUARTER OF WIDTH AND MULTIPLY HEIGHT BY TWO BECAUSE OF SCALING
    self.groundNodeLeft.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(self.frame.size.width / 2, groundTexture.size.height*2 - self.ballDepthInSand)]; // SUBTRACTING ALLOWS BALL TO SIT ON SAND
    self.groundNodeLeft.physicsBody.categoryBitMask = floorCategoryLeft;
    self.groundNodeLeft.physicsBody.contactTestBitMask = ballCategory;
    self.groundNodeLeft.physicsBody.dynamic = NO;
    [self addChild:self.groundNodeLeft];
    
    self.groundNodeRight = [SKNode node];
    self.groundNodeRight.position = CGPointMake(self.frame.size.width * 3 / 4, resultantHeight - 10 ); // CENTERS ONE QUARTER OF WIDTH AND MULTIPLY HEIGHT BY TWO BECAUSE OF SCALING
    self.groundNodeRight.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(self.frame.size.width / 2, groundTexture.size.height*2 - self.ballDepthInSand)]; // SUBTRACTING ALLOWS BALL TO SIT ON SAND
    self.groundNodeRight.physicsBody.categoryBitMask = floorCategoryRight;
    self.groundNodeRight.physicsBody.contactTestBitMask = ballCategory;
    self.groundNodeRight.physicsBody.dynamic = NO;
    [self addChild:self.groundNodeRight];

}

#pragma mark - Touch and Hitting

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    UITouch *firstTouch = touches.anyObject;
    
    if([self shouldBallBeHit:firstTouch] && self.gameInPlay)
    {
        [self hitTheVolleyBall:firstTouch];
        //SHOWS WHERE TOUCH HAPPENED
        CGPoint touchLocation = [firstTouch locationInNode:self];
        [self removeChildrenInArray:@[self.showsTouchPoint]];
        self.showsTouchPoint.position = touchLocation;
        [self addChild:self.showsTouchPoint];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self removeChildrenInArray:@[self.showsTouchPoint]];
        });
    }
    
    if(self.gameStopped && self.readyToRestart)
    {
        [self setupSceneAndNodes];
        [self sendDataToPlayer:CGVectorMake(0, 0) location:self.volleyBall.position updateOrTap:@"restartGame" dataSendMode:MCSessionSendDataReliable];
    }
    
}


-(bool)shouldBallBeHit:(UITouch *)firstTouch
{
    if(self.gameStopped)
    {
        return NO;
    }
    CGPoint ballTouch = [firstTouch locationInNode:self.volleyBall];
    CGFloat xDistance = ballTouch.x;
    CGFloat yDistance = ballTouch.y;
    CGFloat heightVolleyball = self.volleyBall.size.height;
    CGFloat ballCourtSide = self.volleyBall.position.x;
    BOOL shouldHitBall = 1;
    
    
    if(self.hostValue ==0)  // IF PLAYER ONE
    {
        bool correctSideOfCourt = (self.frame.size.width/2 >= ballCourtSide);  //IS THE BALL ON THE CORRECT SIDE OF THE COURT
        bool lessThanThreeHits = ([GameAndScoreDetails sharedGameDataStore].leftPlayerHits < self.allowableHits); //HAVE THEY ALREADY HIT TOO MANY TIMES
        shouldHitBall = (correctSideOfCourt && lessThanThreeHits);
    } else if (self.hostValue == 1)  //IF PLAYER 2
    {
        bool correctSideOfCourt = (self.frame.size.width/2 <= ballCourtSide); //IS THE BALL ON THE CORRECT SIDE OF THE COURT
        bool lessThanThreeHits = ([GameAndScoreDetails sharedGameDataStore].rightPlayerHits < self.allowableHits); //HAVE THEY ALREADY HIT TOO MANY TIMES
        shouldHitBall = (correctSideOfCourt && lessThanThreeHits);
    }
    
    bool closeToTheBall = (ABS(xDistance) < heightVolleyball*1.5) && (ABS(yDistance) < heightVolleyball*1.5);
    
    
    if (closeToTheBall && shouldHitBall)
    {
        if(!self.gameInPlay && !self.readyToRestart)
        {
            self.physicsWorld.gravity = CGVectorMake(0.0, self.gravityValue);
            self.gameInPlay = YES;
        }
    }
    
    if (self.frame.size.width/2 > ballCourtSide && shouldHitBall && closeToTheBall)
    {
        [self.localGameStore leftPlayerHitTheBall];
        self.localGameStore.rightPlayerHits = 0;
    } else if (self.frame.size.width/2 < ballCourtSide && shouldHitBall && closeToTheBall)
    {
        [self.localGameStore rightPlayerHitTheBall];
        self.localGameStore.leftPlayerHits = 0;
    }
    
    return closeToTheBall && shouldHitBall;
}


-(void)hitTheVolleyBall:(UITouch *)firstTouch
{
    CGPoint ballLocation = self.volleyBall.position;
    CGPoint touchLocation = [firstTouch locationInNode:self];
    CGFloat forceHit = 100;
    
    CGPoint pointForRatio = pointSubtract(touchLocation, ballLocation);
    CGFloat xBallVector = forceHit * (pointForRatio.x / -ABS(pointForRatio.y));
    xBallVector = constrainFloat(-forceHit, forceHit, xBallVector);
    CGFloat yBallVector = forceHit * (pointForRatio.y / -ABS(pointForRatio.x));
    yBallVector = constrainFloat(-0.75*forceHit, forceHit, yBallVector);
    
    self.volleyBall.physicsBody.velocity = CGVectorMake(0,0); // ball mass is 0.26420798897743225
    [self.volleyBall.physicsBody applyImpulse:CGVectorMake(xBallVector,yBallVector)]; // bird mass 0.02010619267821312
    [self sendDataToPlayer:CGVectorMake(xBallVector,yBallVector) location:ballLocation updateOrTap:@"tap" dataSendMode:MCSessionSendDataReliable];
    self.lastTapper = YES;
}

#pragma mark - contact made

-(void)didBeginContact:(SKPhysicsContact *)contact
{
    
    bool leftSideFall = (contact.bodyA.categoryBitMask == floorCategoryLeft || contact.bodyB.categoryBitMask == floorCategoryLeft);
    bool rightSideFall = (contact.bodyA.categoryBitMask == floorCategoryRight || contact.bodyB.categoryBitMask == floorCategoryRight);
    bool netHit = (contact.bodyA.categoryBitMask == fenceCategory || contact.bodyB.categoryBitMask == fenceCategory);
    
    if (leftSideFall)
    {
        if(self.gameInPlay)
        {
            [self flashBackgroundScreen:nil];
            [[GameAndScoreDetails sharedGameDataStore] rightPlayerScored];
            [self placeRestartGameButton];
        }
        NSLog(@"Left side Hit");
        self.gameInPlay = NO;
        
    } else if (rightSideFall)
    {
        if(self.gameInPlay)
        {
            [self flashBackgroundScreen:nil];
            [[GameAndScoreDetails sharedGameDataStore] leftPlayerScored];
            [self placeRestartGameButton];
        }
        NSLog(@"Right side Hit");
        self.gameInPlay = NO;
    } else if (netHit)
    {
        if(self.gameInPlay)
        {
            [self flashBackgroundScreen:[SKColor grayColor]];
        }
        NSLog(@"Net was hit");
    }
    [self updateScoreLabelNode];
    
}


-(void)flashBackgroundScreen:(SKColor *)color
{
    __block NSUInteger count = 3;
    [self removeActionForKey:@"flash"];
    [self runAction:[SKAction sequence:@[[SKAction repeatAction:[SKAction sequence:@[[SKAction runBlock:^{
        self.backgroundColor = [SKColor redColor];
        if (color)
        {
            self.backgroundColor = color;
            count = 1;
        }
    }], [SKAction waitForDuration:0.1], [SKAction runBlock:^{
        self.backgroundColor = _skyColor;
    }], [SKAction waitForDuration:0.1]]] count:count], [SKAction runBlock:^{
        //UPON COMPLETION
    }]]] withKey:@"flash"];
}


#pragma mark - multiplayer handling

-(void)dataWasReceived:(NSData *)data
{
    if(!self.gameInPlay)
    {
        self.physicsWorld.gravity = CGVectorMake(0.0, self.gravityValue);
    }
    NSDictionary *gameDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NSString *stringVector = gameDictionary[@"vector"];
    NSString *stringPoint = gameDictionary[@"point"];
    NSString *updateOrTap = gameDictionary[@"updateOrTap"];
    CGVector hitVector = CGVectorFromString(stringVector);
    CGPoint ballLocalation = CGPointFromString(stringPoint);
    
    if (self.lastTapper == NO && ![updateOrTap isEqualToString:@"restartGame"])
    {
        [self otherMultiplayerTap:hitVector location:ballLocalation updateOrTap:updateOrTap];
    } else if ([updateOrTap isEqualToString:@"tap"])
    {
        [self otherMultiplayerTap:hitVector location:ballLocalation updateOrTap:updateOrTap];
        self.lastTapper = NO;
    } else if ([updateOrTap isEqualToString:@"restartGame"])
    {
        [self setupSceneAndNodes];
    }
    
}

-(void)otherMultiplayerTap:(CGVector)vector location:(CGPoint)location updateOrTap:(NSString *)type
{
    self.volleyBall.position = location;
    if([type isEqualToString:@"tap"])
    {
        self.volleyBall.physicsBody.velocity = CGVectorMake(0,0);
        [self.volleyBall.physicsBody applyImpulse:vector];
    } else
    {
        self.volleyBall.physicsBody.velocity = vector;
    }
    
}


-(void)sendDataToPlayer:(CGVector)hitVector
               location:(CGPoint)location
                   updateOrTap:(NSString *)type
           dataSendMode:(MCSessionSendDataMode)dataSendMode
{
    if (!dataSendMode)
    {
        dataSendMode = MCSessionSendDataReliable;
    }
    
    if (self.hostValue != 2) // && !self.gameInPlay)
    {
        NSString *stringVector = NSStringFromCGVector(hitVector);
        NSString *stringPoint = NSStringFromCGPoint(location);
        NSDictionary *gameDictionary = @{@"vector" : stringVector,
                                         @"point" : stringPoint,
                                         @"updateOrTap" : type};
        NSData *sendingData = [NSKeyedArchiver archivedDataWithRootObject:gameDictionary];
        [self.partyTime sendData:sendingData withMode:(dataSendMode) error:nil];
    }
}

//-(void)temporarilyTurnOffDataReceiving:(NSUInteger)xSeconds
//{
//    if(!xSeconds)
//    {
//        xSeconds = 0.1;
//    }
//    self.allowReceivingData = NO;
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(xSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        self.allowReceivingData = YES;
//    });
//    
//}


#pragma mark - math helper

CGFloat constrainFloat(CGFloat min, CGFloat max, CGFloat value) {
    if( value > max ) {
        return max;
    } else if( value < min ) {
        return min;
    } else {
        return value;
    }
}



#pragma mark - Transformations
static inline CGPoint transformForHit(CGPoint a , CGPoint b) {
    
    return CGPointMake(a.x, b.y);
}

static inline CGPoint pointAddition(CGPoint a, CGPoint b) {
    return CGPointMake(a.x + b.x, a.y + b.y);
}

static inline CGPoint pointSubtract(CGPoint a, CGPoint b) {
    return CGPointMake(a.x - b.x, a.y - b.y);
}

static inline CGPoint pointMultiply(CGPoint a, float b) {
    return CGPointMake(a.x * b, a.y * b);
}

static inline float Length(CGPoint a) {
    return sqrtf(a.x * a.x + a.y * a.y);
}

// Makes a vector have a length of 1
static inline CGPoint pointNormalize(CGPoint a) {
    float length = Length(a);
    return CGPointMake(a.x / length, a.y / length);
}


@end
