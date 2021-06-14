package com.ero.downloader_manager;

import android.app.DownloadManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.database.Cursor;
import android.net.Uri;
import android.util.Log;

import androidx.annotation.NonNull;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import static android.app.DownloadManager.STATUS_RUNNING;
import static android.content.Context.DOWNLOAD_SERVICE;

/** DownloaderManagerPlugin */
public class DownloaderManagerPlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private EventChannel eventChannel;
  private DownloadManager downloadManager;

  BroadcastReceiver onComplete = new BroadcastReceiver() {
    public void onReceive(Context context, Intent intent) {
      long completeDownloadId = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, 0L);
      channel.invokeMethod("complete", completeDownloadId);
    }
  };

  BroadcastReceiver onNotificationClick = new BroadcastReceiver() {
    public void onReceive(Context context, Intent intent) {
      long completeDownloadId = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, 0L);
      channel.invokeMethod("click", completeDownloadId);
    }
  };

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "downloader_manager");
    channel.setMethodCallHandler(this);

    Context context = flutterPluginBinding.getApplicationContext();
    downloadManager = (DownloadManager)context.getSystemService(DOWNLOAD_SERVICE);
    context.registerReceiver(onComplete,
            new IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE));
    context.registerReceiver(onNotificationClick,
            new IntentFilter(DownloadManager.ACTION_NOTIFICATION_CLICKED));
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("setup")) {
      Cursor cursor = downloadManager.query(new DownloadManager.Query());
      ArrayList res = new ArrayList();
      while (cursor.moveToNext()) {
        HashMap map = new HashMap();
        map.put("id", cursor.getInt(cursor.getColumnIndex(DownloadManager.COLUMN_ID)));
        int status = cursor.getInt(cursor.getColumnIndex(DownloadManager.COLUMN_STATUS));
        if ((status & DownloadManager.STATUS_SUCCESSFUL) != 0) {
          map.put("status", 2);
        } else {
          map.put("status", 1);
        }
        long loaded = cursor.getLong(cursor.getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR));
        map.put("loaded", loaded);
        long total = cursor.getLong(cursor.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES));
        map.put("total", total);
        map.put("local", cursor.getString(cursor.getColumnIndex(DownloadManager.COLUMN_LOCAL_URI)));
        res.add(map);
      }
      result.success(res);
    } else if (call.method.equals("state")) {
      long id = ((Number)call.argument("id")).longValue();
      Cursor cursor = downloadManager.query(new DownloadManager.Query().setFilterById(id));
      HashMap res = new HashMap();
      if (cursor == null || !cursor.moveToFirst()) {
        res.put("status", 0);
      } else {
        int status = cursor.getInt(cursor.getColumnIndex(DownloadManager.COLUMN_STATUS));
        if ((status & DownloadManager.STATUS_SUCCESSFUL) != 0) {
          res.put("status", 2);
        } else {
          res.put("status", 1);
        }
        long loaded = cursor.getLong(cursor.getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR));
        res.put("loaded", loaded);
        long total = cursor.getLong(cursor.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES));
        res.put("total", total);
      }
      result.success(res);
    } else if (call.method.equals("enqueue")) {
      Uri uri = Uri.parse((String)call.argument("url"));
      DownloadManager.Request request = new DownloadManager.Request(uri);
      Map<String, String> headers = call.argument("headers");
      for (String key : headers.keySet()) {
        request.addRequestHeader(key, headers.get(key));
      }
      request.setDestinationUri(Uri.fromFile(new File((String)call.argument("file"))));
      request.setTitle((String)call.argument("title"));
      request.setDescription((String)call.argument("description"));
      request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE);
      request.setAllowedOverRoaming(true);

      long downloadId = downloadManager.enqueue(request);
      result.success(downloadId);
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    Context context = binding.getApplicationContext();
    context.unregisterReceiver(onComplete);
    context.unregisterReceiver(onNotificationClick);
  }
}
