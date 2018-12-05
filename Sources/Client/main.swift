import NIO
import Foundation

typealias Bytes = [UInt8]

final class Handler: ChannelDuplexHandler {
    typealias InboundIn = ByteBuffer
    typealias InboundOut = ByteBuffer
    typealias OutboundIn = String
    typealias OutboundOut = ByteBuffer
    
    let promise: EventLoopPromise<Void>
    
    init(promise: EventLoopPromise<Void>) {
        self.promise = promise
    }
    
    func userInboundEventTriggered(ctx: ChannelHandlerContext, event: Any) {
        if let _ = event as? IdleStateHandler.IdleStateEvent {
            print("Client timed out")
            ctx.close(promise: nil)
        }
        ctx.fireUserInboundEventTriggered(event)
    }
    
    func write(ctx: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let string = self.unwrapOutboundIn(data)
        let stringBytes = Bytes(string.utf8)
        var buffer = ctx.channel.allocator.buffer(capacity: stringBytes.count)
        buffer.write(bytes: stringBytes)
        print("Written \(string)")
        ctx.writeAndFlush(self.wrapOutboundOut(buffer), promise: promise)
    }
    
    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        print("Channelread")
        var buffer = self.unwrapInboundIn(data)
        let bytes = buffer.readBytes(length: buffer.readableBytes)!
        print("Received string: \(String(bytes: bytes, encoding: .ascii)!)")
        self.promise.succeed(result: ())
        ctx.close(promise: nil)
    }
}

let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

let promise: EventLoopPromise<Void> = group.next().newPromise()

let bootstrap = ClientBootstrap(group: group)
    .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
    .channelInitializer { channel in
        channel.pipeline.add(handler: IdleStateHandler(readTimeout: .seconds(1), writeTimeout: .seconds(1))).then {
        channel.pipeline.add(handler: Handler(promise: promise))
    }}

let channel = try bootstrap.connect(host: "localhost", port: 1337).wait()

try channel.writeAndFlush("ping").wait()

try promise.futureResult.wait()
