import Foundation
import NIO

typealias Bytes = [UInt8]

final class Handler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias InboundOut = ByteBuffer
    typealias OutboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer
    
    func userInboundEventTriggered(ctx: ChannelHandlerContext, event: Any) {
        if let _ = event as? IdleStateHandler.IdleStateEvent {
            print("Client timed out")
            ctx.close(promise: nil)
        }
        ctx.fireUserInboundEventTriggered(event)
    }
    
    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        var data = self.unwrapInboundIn(data)
        let bytes = data.readBytes(length: data.readableBytes)!
        let pong = "pong"
        print("Read string: \(String(bytes: bytes, encoding: .ascii)!)")
        
        fatalError("> Crash!")
        
        let responseBytes = Bytes("\(pong)\n".utf8)
        var buffer = ctx.channel.allocator.buffer(capacity: responseBytes.count)
        buffer.write(bytes: responseBytes)
        ctx.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)
        print("Written back: \(pong)")
        ctx.close(promise: nil)
    }
}

let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
let bootstrap = ServerBootstrap(group: group)
    .serverChannelOption(ChannelOptions.backlog, value: 256)
    .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
    
    .childChannelInitializer { channel in
        channel.pipeline.add(handler: BackPressureHandler()).then {
        channel.pipeline.add(handler: IdleStateHandler(readTimeout: .seconds(1), writeTimeout: .seconds(1))).then {
        channel.pipeline.add(handler: Handler())
    }}}
    
    .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
    .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
    .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 64)
    .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())

let channel = try bootstrap.bind(host: "127.0.0.1", port: 1337).wait()

print("Started server at 127.0.0.1:1337")

try channel.closeFuture.wait()
