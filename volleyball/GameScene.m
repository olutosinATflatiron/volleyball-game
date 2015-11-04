//
//  GameScene.m
//  volleyball
//
//  Created by JASON HARRIS on 11/3/15.
//  Copyright (c) 2015 Jason Harris. All rights reserved.
//

#import "GameScene.h"

@interface GameScene () <SKPhysicsContactDelegate>
@property (nonatomic, strong) SKShapeNode *showsTouchPoint;
@property (nonatomic, strong) SKSpriteNode *volleyBall;
@property (nonatomic, strong) SKColor *skyColor;
@property (nonatomic, strong) SKNode *groundNode;
@property (nonatomic, strong) SKNode *wallNodeOne;
@property (nonatomic, strong) SKNode *wallNodeTwo;


@end


@implementation GameScene

// scene categories
static const uint32_t ballCategory = 1 << 0;
static const uint32_t fenceCategory = 1 << 1;
static const uint32_t worldCategory = 1 << 2;
static const uint32_t floorCategory = 1 << 3;
static const uint32_t ceilingCategory = 1 << 4;
// scene categories



-(void)didMoveToView:(SKView *)view {
    /* Setup your scene here */
    self.physicsWorld.gravity = CGVectorMake(0.0, -2.5);
    self.physicsWorld.contactDelegate = self;
    
    self.skyColor = [SKColor colorWithRed:112/255.0 green:200/255.0 blue:230/255.0 alpha:1.0];
    self.skyColor = [SKColor blackColor];
    [self setBackgroundColor:self.skyColor];
    
    //the touch point
    self.showsTouchPoint = [[SKShapeNode alloc] init];
    CGMutablePathRef ballPath = CGPathCreateMutable();
    CGPathAddArc(ballPath, NULL, 0,0, 15, 0, M_PI*2, YES);
    self.showsTouchPoint.path = ballPath;
    self.showsTouchPoint.lineWidth = 1.0;
    self.showsTouchPoint.fillColor = [SKColor darkGrayColor];
    self.showsTouchPoint.alpha = 0.5;
    self.showsTouchPoint.glowWidth = 0.0;
    self.showsTouchPoint.zPosition = 10;
    
    
    
    
    // volleyball
    SKTexture *volleyballTexture = [SKTexture textureWithImageNamed:@"Volleyball"];
    volleyballTexture.filteringMode = SKTextureFilteringNearest;
    
    self.volleyBall = [SKSpriteNode spriteNodeWithTexture:volleyballTexture];
    self.volleyBall.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:self.volleyBall.size.height/2];
    self.physicsBody.allowsRotation = YES;
    self.volleyBall.physicsBody.dynamic = YES;
    self.physicsBody.categoryBitMask = ballCategory;
    self.physicsBody.collisionBitMask = fenceCategory | worldCategory | ceilingCategory | floorCategory; // bounces off
    self.physicsBody.contactTestBitMask = fenceCategory | floorCategory; // notifications when collisions
    self.volleyBall.zPosition = 5.0;
    self.volleyBall.position = CGPointMake(self.size.width*1/6, self.size.height*4/5);
    
    [self addChild:self.volleyBall];
    
    //ground set up
    SKTexture *groundTexture = [SKTexture textureWithImageNamed:@"Ground"];
    groundTexture.filteringMode = SKTextureFilteringNearest;
    for(NSUInteger i = 0 ; i < 2 + self.frame.size.width/(groundTexture.size.width*2); i++)
    {
        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithTexture:groundTexture];
        [sprite setScale:2.0];
        sprite.position = CGPointMake(i*sprite.size.width, sprite.size.height / 2 + groundTexture.size.height * 2);
        [self addChild:sprite];
    }
    
    self.groundNode = [SKNode node];
    self.groundNode.position = CGPointMake(0, groundTexture.size.height);
    self.groundNode.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(self.frame.size.width*10, groundTexture.size.height*5)];
    self.groundNode.physicsBody.categoryBitMask = floorCategory;
    self.groundNode.physicsBody.contactTestBitMask = ballCategory;
    self.groundNode.physicsBody.dynamic = NO;
    [self addChild:self.groundNode];
    
    //wall one set up
    self.wallNodeOne = [SKNode node];
    self.wallNodeOne.position = CGPointMake(0, 0);
    self.wallNodeOne.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(1, [UIScreen mainScreen].bounds.size.height*10)];
    self.wallNodeOne.physicsBody.categoryBitMask = worldCategory;
    self.wallNodeOne.physicsBody.dynamic = NO;
    [self addChild:self.wallNodeOne];
    //wall two set up
    self.wallNodeTwo = [SKNode node];
    self.wallNodeTwo.position = CGPointMake(self.frame.size.width, 0);
    self.wallNodeTwo.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(1, [UIScreen mainScreen].bounds.size.height*10)];
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
    
    
    //fence node
    SKNode *fenceNode = [SKNode node];
    fenceNode.position = CGPointMake(self.frame.size.width/2 , 0);
    fenceNode.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(15, self.frame.size.height)];
    fenceNode.physicsBody.categoryBitMask = fenceCategory;
    fenceNode.physicsBody.contactTestBitMask = ballCategory;
    fenceNode.physicsBody.dynamic = NO;
    fenceNode.physicsBody.allowsRotation = NO;
    [self addChild:fenceNode];
    
    
    NSLog(@"%f width %f height",self.frame.size.width,self.frame.size.height);
    
    
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    
}


#pragma mark - Touch and Hitting

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    UITouch *firstTouch = touches.anyObject;
    
    CGPoint ballTouch = [firstTouch locationInNode:self.volleyBall];
    CGFloat xDistance = ballTouch.x;
    CGFloat yDistance = ballTouch.y;
    CGFloat heightVolleyball = self.volleyBall.size.height;
    if( (ABS(xDistance) < heightVolleyball*1.5) && (ABS(yDistance) < heightVolleyball*1.5) )
       {
        [self hitTheVolleyBall:firstTouch];
       }
    
    CGPoint touchLocation = [firstTouch locationInNode:self];
    [self removeChildrenInArray:@[self.showsTouchPoint]];
    self.showsTouchPoint.position = touchLocation;
    [self addChild:self.showsTouchPoint];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self removeChildrenInArray:@[self.showsTouchPoint]];
    });
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
    
}

-(void)didBeginContact:(SKPhysicsContact *)contact
{
    NSLog(@"Floor or net hit");
    // Flash background if contact is detected
    
    [self removeActionForKey:@"flash"];
    [self runAction:[SKAction sequence:@[[SKAction repeatAction:[SKAction sequence:@[[SKAction runBlock:^{
        self.backgroundColor = [SKColor redColor];
    }], [SKAction waitForDuration:0.05], [SKAction runBlock:^{
        self.backgroundColor = _skyColor;
    }], [SKAction waitForDuration:0.05]]] count:2], [SKAction runBlock:^{
        // CAN RESTART GAME WOULD BE PUT HERE
    }]]] withKey:@"flash"];
    
}

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