//
//  Packet.m
//
//  Created by Ray Wenderlich on 5/25/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "Packet.h"
#import "NSData+Additions.h"

const size_t PACKET_HEADER_SIZE = 10;

@implementation Packet

@synthesize packetType = _packetType;

+ (id)packetWithType:(PacketType)packetType message:(NSString*)message;
{
	return [[[self class] alloc] initWithType:packetType message:message];
}

+ (id)packetWithData:(NSData *)data
{
	if ([data length] < PACKET_HEADER_SIZE)
	{
		NSLog(@"Error: Packet too small");
		return nil;
	}
    
	if ([data rw_int32AtOffset:0] != 'DEMO')
	{
		NSLog(@"Error: Packet has invalid header");
		return nil;
	}
    
	size_t count;
	PacketType packetType = [data rw_int16AtOffset:8];
	NSString *message = [data rw_stringAtOffset:PACKET_HEADER_SIZE bytesRead:&count];
	Packet *packet = [Packet packetWithType:packetType message:message];
	return packet;
}

- (id)initWithType:(PacketType)packetType message:(NSString*)message;
{
	if ((self = [super init]))
	{
		self.packetType = packetType;
		self.packetMessage = message;
	}
	return self;
}

- (NSData *)data
{
	NSMutableData *data = [[NSMutableData alloc] initWithCapacity:100];
	[data rw_appendInt32:'DEMO'];
	[data rw_appendInt32:0];
	[data rw_appendInt16:self.packetType];
    [self addPayloadToData:data];
    
	return data;
}

- (void)addPayloadToData:(NSMutableData *)data
{
	[data rw_appendString:self.packetMessage];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@, type=%d", [super description], self.packetType];
}

@end
