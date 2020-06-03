package com.babariviere.sms;

import com.babariviere.sms.permisions.Permissions;
import com.babariviere.sms.status.SmsStateHandler;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.common.StandardMethodCodec;

/**
 * SmsPlugin
 */
public class SmsPlugin {
    private static final String CHANNEL_RECV = "plugins.babariviere.com/recvSMS";
    private static final String CHANNEL_SMS_STATUS = "plugins.babariviere.com/statusSMS";
    private static final String CHANNEL_SEND = "plugins.babariviere.com/sendSMS";
    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {

        registrar.addRequestPermissionsResultListener(Permissions.getRequestsResultsListener());

       
        // SMS receiver
        final SmsReceiver receiver = new SmsReceiver(registrar);
        final EventChannel receiveSmsChannel = new EventChannel(registrar.messenger(),
                CHANNEL_RECV, JSONMethodCodec.INSTANCE);
        receiveSmsChannel.setStreamHandler(receiver);

        // SMS status receiver
        new EventChannel(registrar.messenger(), CHANNEL_SMS_STATUS, JSONMethodCodec.INSTANCE)
                .setStreamHandler(new SmsStateHandler(registrar));

        /// SMS sender
        final SmsSender sender = new SmsSender(registrar);
        final MethodChannel sendSmsChannel = new MethodChannel(registrar.messenger(),
                CHANNEL_SEND, JSONMethodCodec.INSTANCE);
        sendSmsChannel.setMethodCallHandler(sender);
}
}
