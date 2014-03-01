//
//  Packet.h
//
//  Created by Ray Wenderlich on 5/25/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

typedef enum
{
	PacketTypeMessage
}
PacketType;

@interface Packet : NSObject

@property (nonatomic, assign) PacketType packetType;
@property (nonatomic, retain) NSString* packetMessage;

+ (id)packetWithType:(PacketType)packetType message:(NSString*)message;
- (id)initWithType:(PacketType)packetType message:(NSString*)message;
+ (id)packetWithData:(NSData *)data;

- (NSData *)data;

@end
