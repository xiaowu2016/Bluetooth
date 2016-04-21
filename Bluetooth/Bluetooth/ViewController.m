//
//  ViewController.m
//  Bluetooth
//
//  Created by zhangchao on 16/4/21.
//  Copyright © 2016年 zhangchao. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>
@property (nonatomic,strong) CBCentralManager *myCentralManager;
@property (nonatomic,strong) CBPeripheral *myPeripheral;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
#pragma mark 1 Starting Up a Central Manager(启动一个Central Manager)
    //这里的queue如果为nil就会在主线程
    self.myCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    
}

#pragma mark 2 扫描外设（discover），扫描外设的方法我们放在centralManager成功打开的委托中，因为只有设备成功打开，才能开始扫描，否则会报错。
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    //开始扫描周围的外设
    if(central.state == CBCentralManagerStatePoweredOn)
    {
        //第一个参数nil就是扫描周围所有的外设
        [self.myCentralManager scanForPeripheralsWithServices:nil options:nil];
    }
}

#pragma mark 3 连接外设(connect)
//扫描到设备会进入方法
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
 
    NSLog(@"当扫描到设备:%@",peripheral.name);
    
    //这里自己去设置下连接规则，我设置的是8结尾的设备
    if([peripheral.name hasSuffix:@"8"])
    {//一个主设备最多能连7个外设，每个外设最多只能给一个主设备连接,连接成功，失败，断开会进入各自的委托
        //停止搜索
        [self.myCentralManager stopScan];
      
        //这里先将peripheral值保存一下，有时会自动销毁导致连接不上
        self.myPeripheral = peripheral;
        //连接外设
        [self.myCentralManager connectPeripheral:self.myPeripheral options:nil];
        
    }
}

//连接到Peripherals-失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"===>>>连接到名称为（%@）的设备-失败,原因:%@",[peripheral name],[error localizedDescription]);
}

//Peripherals断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"===>>>外设连接断开连接 %@: %@\n", [peripheral name], [error localizedDescription]);
}

#pragma mark 4 扫描外设中的服务和特征(discover)

//连接到Peripherals-成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"===>>>连接到名称为（%@）的设备-成功",peripheral.name);
    //设置的peripheral委托CBPeripheralDelegate
    [peripheral setDelegate:self];

    //扫描外设Services
    [peripheral discoverServices:nil];
}


//扫描到Services
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    NSLog(@"===>>>扫描到服务：%@",peripheral.services);
    if (error)
    {
        NSLog(@"===>>>Discovered services for %@ with error: %@", peripheral.name, [error localizedDescription]);
        return;
    }
    for (CBService *service in peripheral.services)
    {
        NSLog(@"%@",service.UUID);
        //扫描每个service的Characteristics
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

#pragma mark 5 与外设做数据交互
//扫描到Characteristics
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (error)
    {
        NSLog(@"error Discovered characteristics for %@ with error: %@", service.UUID, [error localizedDescription]);
        return;
    }
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        NSLog(@"service:%@ 的 Characteristic: %@",service.UUID,characteristic.UUID);
    }
    //获取Characteristic的值
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        [peripheral readValueForCharacteristic:characteristic];
    }
    //搜索Characteristic的Descriptors
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        [peripheral discoverDescriptorsForCharacteristic:characteristic];
    }
}


//获取的charateristic的值
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    //打印出characteristic的UUID和值
    //!注意，value的类型是NSData，具体开发时，会根据外设协议制定的方式去解析数据
    NSLog(@"characteristic uuid:%@  value:%@",characteristic.UUID,characteristic.value);
    //写入数据到外设中
//    [self.myPeripheral writeValue:<#(nonnull NSData *)#> forCharacteristic:<#(nonnull CBCharacteristic *)#> type:<#(CBCharacteristicWriteType)#>]
    
}

//搜索到Characteristic的Descriptors
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    //打印出Characteristic和他的Descriptors
    NSLog(@"characteristic uuid:%@",characteristic.UUID);
    for (CBDescriptor *d in characteristic.descriptors) {
        NSLog(@"Descriptor uuid:%@",d.UUID);
    }
}

//获取到Descriptors的值
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    //打印出DescriptorsUUID 和value
    //这个descriptor都是对于characteristic的描述，一般都是字符串，所以这里我们转换成字符串去解析
    NSLog(@"characteristic uuid:%@  value:%@",[NSString stringWithFormat:@"%@",descriptor.UUID],descriptor.value);
    //写入数据到外设中
//    [self.myPeripheral writeValue:<#(nonnull NSData *)#> forDescriptor:<#(nonnull CBDescriptor *)#>]
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
