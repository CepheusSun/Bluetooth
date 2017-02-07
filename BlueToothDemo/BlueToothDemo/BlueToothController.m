//
//  BlueToothController.m
//  BlueToothDemo
//
//  Created by 孙扬 on 2017/2/7.
//  Copyright © 2017年 ProgrammerSunny. All rights reserved.
//

#import "BlueToothController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface BlueToothController () <CBCentralManagerDelegate, CBPeripheralDelegate>{
    // 系统蓝牙设备管理对象，通过它去扫描和链接外部设别
    CBCentralManager *_bluetoothManager;
    // 周边设备列表
    NSMutableArray *_peropherals;
}
// 显示 当前蓝牙状态
@property (weak, nonatomic) IBOutlet UILabel *bluetoothStateLabel;
@end

/*
 设置 manager 的委托, CBCentralManagerDelegate
  需要实现的方法
 
 1、 初始化 manager 对象
 2、 扫描外部设备
 3、 连接外部设备
 4、 扫描外部设备中的服务和特征
    1、 获取外部设备的服务
    2、 获取外部设备的特征
 5、 数据交互
 6、 订阅特征的通知
 7、 断开链接
 */


@implementation BlueToothController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 默认为 mainqueue
    // _bluetoothManager = [[CBCentralManager alloc] initWithDelegate:self  queue:nil];
    _peropherals = [NSMutableArray array];
    _bluetoothManager = [[CBCentralManager alloc] initWithDelegate:self
                                                             queue:dispatch_get_main_queue()];
}

- (void)viewDidDisappear:(BOOL)animated {
    for (CBPeripheral *peripheral in _peropherals) {
        [self disconnect:_bluetoothManager peripheral:peripheral];
    }
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    // manager 状态改变的委托，在初始化 CBCentralManager 的时候会打开设备，
    // 只有当设备正确打开后才能使用
    
    /*central.state
     CBManagerStateUnknown = 0,  // 未知
     CBManagerStateResetting,    // 复位
     CBManagerStateUnsupported,  // 蓝牙设备不支持蓝牙低功耗
     CBManagerStateUnauthorized, // App 无权使用蓝牙低功耗
     CBManagerStatePoweredOff,   // 关闭状态
     CBManagerStatePoweredOn,    // 开启状态 只有在这个状态下才能扫描外部设备
     */
    
    switch (central.state) {
        case CBManagerStateUnknown:
        _bluetoothStateLabel.text = @"CBManagerStateUnknown";
        break;
        case CBManagerStateResetting:
        _bluetoothStateLabel.text = @"CBManagerStateResetting";
        break;
        case CBManagerStateUnsupported:
        _bluetoothStateLabel.text = @"CBManagerStateUnsupported";
        break;
        case CBManagerStateUnauthorized:
        _bluetoothStateLabel.text = @"CBManagerStateUnauthorized";
        break;
        case CBManagerStatePoweredOff:
        _bluetoothStateLabel.text = @"CBManagerStatePoweredOff";
        break;
        case CBManagerStatePoweredOn:
        _bluetoothStateLabel.text = @"CBManagerStatePoweredOn";
        // 只有在这个状态下才能扫描外部设备
        
#pragma mark 开始扫描外部设备
        // 扫描结果在 didDiscoverPeripheral 方法中回掉
        // [_bluetoothManager scanForPeripheralsWithServices:<#(nullable NSArray<CBUUID *> *)#> options:<#(nullable NSDictionary<NSString *,id> *)#>]
        // serviceUUIDs：代表该app所感兴趣的服务uuids数组（也就是该app想要连接的外设）
        [_bluetoothManager scanForPeripheralsWithServices:nil options:nil];
        
        break;
    }
    
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
 //找到外设的委托
    NSLog(@"%@",peripheral.name);
#pragma mark 连接设备
    // 一个 manager 最多能连接 7 个外部设备，每个外部设备最多能跟一个主要设备连接
    // 使用小米手环测试, 这里判断一下, 免得浪费时间
    if ([peripheral.name hasPrefix:@"MI"]) {
        [_peropherals addObject:peripheral];
        [_bluetoothManager connectPeripheral:peripheral options:nil];
        // important:
#pragma mark 停止扫描的方法
        [central stopScan];
    }
}
    
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    // 连接外设成功的委托
    NSLog(@">>>连接到（%@）成功", peripheral.name);
#pragma mark 获取设备的service
    peripheral.delegate = self;
    // 扫描外设Services，成功后会进入方法 didDiscoverServices
    [peripheral discoverServices:nil];
}
    
    
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
 //外设连接失败的委托
    NSLog(@">>>连接到名称为（%@）的设备-失败,原因:%@",[peripheral name],[error localizedDescription]);
}
    
    
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
 //断开外设的委托
    [_peropherals removeObject:peripheral];
    NSLog(@">>>外设连接断开连接 %@: %@\n", peripheral.name, error.localizedDescription);
}
    
#pragma mark - CBPeripheralDelegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    // 扫描到外部设备的 service
    if (error) {
        // 有什么错误
        NSLog(@">>> 发现%@ 错误%@",peripheral.name, error.localizedDescription);
        return;
    }
    for (CBService *service in peripheral.services) {
        NSLog(@"service uuid: %@",service.UUID);
#pragma mark 获取 service 的特征
        [peripheral discoverCharacteristics:nil forService:service];
    }
}
    
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    // 扫描到 service 的特征
    if (error) {
        NSLog(@">>>>service:%@ error : %@",service.UUID , error.localizedDescription);
        return;
    }
#pragma mark 获取特征的值
    //获取Characteristic的值，读到数据会进入方法：didUpdateValueForCharacteristic
    for (CBCharacteristic *characteristic in service.characteristics) {
        [peripheral readValueForCharacteristic:characteristic];
    }
#pragma mark 获取特征的 Descriptors
    //搜索Characteristic的Descriptors，读到数据会进入方法didDiscoverDescriptorsForCharacteristic
    for (CBCharacteristic * characteristic in service.characteristics){
        [peripheral discoverDescriptorsForCharacteristic:characteristic];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    // 获取的特征的值
    // 打印出特征的UUID值
    // 注意 这里的 value 是 NSData, 具体实现的时候需要解析数据
    NSLog(@"characteristic uuid:%@ value: %@", characteristic.UUID, characteristic.value);
}
    
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    //搜索到特征的 Descriptors
    //打印出Characteristic和他的Descriptors
    NSLog(@"characteristic uuid:%@",characteristic.UUID);
    for (CBDescriptor *descriptor in characteristic.descriptors) {
        NSLog(@"Descriptor uuid:%@",descriptor.UUID);
    }
}


-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    //获取到Descriptors的值
    //打印出DescriptorsUUID 和value
    //这个descriptor都是对于characteristic的描述，一般都是字符串，所以这里我们转换成字符串去解析
    NSLog(@"characteristic uuid:%@  value:%@",[NSString stringWithFormat:@"%@",descriptor.UUID],descriptor.value);
}
    
#pragma mark - 写入数据的方法
//CBCharacteristic 有很多的权限 读写 广播 balabala....
    /*
     typedef NS_OPTIONS(NSUInteger, CBCharacteristicProperties) {
     CBCharacteristicPropertyBroadcast                                              = 0x01,
     CBCharacteristicPropertyRead                                                   = 0x02,
     CBCharacteristicPropertyWriteWithoutResponse                                   = 0x04,
     CBCharacteristicPropertyWrite                                                  = 0x08,
     CBCharacteristicPropertyNotify                                                 = 0x10,
     CBCharacteristicPropertyIndicate                                               = 0x20,
     CBCharacteristicPropertyAuthenticatedSignedWrites                              = 0x40,
     CBCharacteristicPropertyExtendedProperties                                     = 0x80,
     CBCharacteristicPropertyNotifyEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)        = 0x100,
     CBCharacteristicPropertyIndicateEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)  = 0x200
     };
     
     */
- (void)writePeripheral:(CBPeripheral *)peripheral
         characteristic:(CBCharacteristic *)characteristic
                  value:(NSData *)value {
    // 只有这个特征有写的权限才能写入数据
    if (characteristic.properties & CBCharacteristicPropertyWrite) {
        /*
         typedef NS_ENUM(NSInteger, CBCharacteristicWriteType) {
         CBCharacteristicWriteWithResponse = 0,
         CBCharacteristicWriteWithoutResponse,
         };
        区别是是否会有反馈
         */
        [peripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }else {
        NSLog(@"没有写入权限");
    }
}
    
#pragma mark 订阅特征的通知
- (void)notifyPeripheral:(CBPeripheral *)peripheral
          characteristic:(CBCharacteristic* )characteristic {
    // 设置通知
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
}
    
- (void)cancelNotifyPeripheral:(CBPeripheral *)peripheral
                characteristic:(CBCharacteristic* )characteristic {
    [peripheral setNotifyValue:NO forCharacteristic:characteristic];
}
    
#pragma mark 断开连接
- (void)disconnect:(CBCentralManager *)manager
        peripheral:(CBPeripheral *)peripheral{
    [manager stopScan];
    [manager cancelPeripheralConnection:peripheral];
}
   
@end
