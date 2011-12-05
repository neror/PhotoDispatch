//
//  Helpers.h
//  PhotoDispatch
//
//  Copyright (c) 2011 Nathan Eror & Free Time Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

static CGImageRef CGImageCreateFromURL(CFURLRef url) {
  CGImageSourceRef imageSource = CGImageSourceCreateWithURL(url, NULL);
  if (imageSource == NULL){
    NSLog(@"%@", @"Image source is NULL.");
    CFRelease(imageSource);
    return NULL;
  }
  
  CGImageRef fullImage = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
  CFRelease(imageSource);

  if (fullImage == NULL){
    NSLog(@"%@", @"Thumbnail image not created from image source.");
    return NULL;
  }
  
  return fullImage;
}

static CGImageRef CGImageCreateThumbnailFromImageAtURL(CFURLRef url, int maxPixelSize) {
  CFNumberRef pixelSize = CFNumberCreate(NULL, kCFNumberIntType, &maxPixelSize);
  CFStringRef keys[3] = {
    kCGImageSourceCreateThumbnailWithTransform,
    kCGImageSourceCreateThumbnailFromImageAlways,
    kCGImageSourceThumbnailMaxPixelSize
  };
  
  CFTypeRef values[3] = {
    (CFTypeRef)kCFBooleanTrue,
    (CFTypeRef)kCFBooleanTrue,
    (CFTypeRef)pixelSize
  };

  CFDictionaryRef options = CFDictionaryCreate(NULL, (const void **) keys, (const void **) values, 3, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
  CFRelease(pixelSize);
  
  CGImageSourceRef imageSource = CGImageSourceCreateWithURL(url, options);
  if (imageSource == NULL){
    NSLog(@"%@", @"Image source is NULL.");
    CFRelease(imageSource);
    return NULL;
  }
  
  CGImageRef thumbnailImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options);
  CFRelease(imageSource);

  if (thumbnailImage == NULL){
    NSLog(@"%@", @"Thumbnail image not created from image source.");
    return nil;
  }
  
  return thumbnailImage;
}

static CGImageRef RandomConvolutionCopyOfImage(CGImageRef image) {
  void *inData, *outData;
  
  size_t height = CGImageGetHeight(image);
  size_t width = CGImageGetWidth(image);
  
  size_t rowBytes = width * 4; 
  
  inData = calloc(height, rowBytes);
  outData = calloc(height, rowBytes); 
  
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  
  CGContextRef inBitmapContext = CGBitmapContextCreate(inData, width, height, 8, rowBytes, colorSpace, kCGImageAlphaPremultipliedFirst);
  CGContextRef outBitmapContext = CGBitmapContextCreate(outData, width, height, 8, rowBytes, colorSpace, kCGImageAlphaPremultipliedFirst);
  CGContextDrawImage(inBitmapContext, CGRectMake(0, 0, width, height), image);
  
  const vImage_Buffer inBuffer = { inData, height, width, rowBytes };
  const vImage_Buffer outBuffer = { outData, height, width, rowBytes };
  Pixel_8888 bgColor = { 0, 0, 0, 0 };
  const int16_t kernel[3][9] = {
    {1, 2, 1, 2, 4, 2, 1, 2, 1},
    {-2, -2, 0, -2, 6, 0, 0, 0, 0},
    {-1, -1, -1, 0, 0, 0, 1, 1, 1}
  };
  
  int32_t divisor[3] = { 16, 1, 1 };
  
  int index = arc4random() % 3;
  
  vImage_Error error = vImageConvolveWithBias_ARGB8888(&inBuffer, &outBuffer, NULL, 0, 0, kernel[index], 3, 3, divisor[index], 128, bgColor, kvImageBackgroundColorFill);
  
  if(error != kvImageNoError) {
    NSLog(@"vImage error '%ld' ", error);
  }
  
  CGImageRef convolvedImage = CGBitmapContextCreateImage(outBitmapContext);
  
  CGContextRelease(inBitmapContext);
  CGContextRelease(outBitmapContext);
  CGColorSpaceRelease(colorSpace);
  free(inData);
  free(outData);
  return convolvedImage;
}

static CGImageRef RandomConvolutionCopyOfImageAtURL(CFURLRef url) {
  CGImageRef fullImage = CGImageCreateFromURL(url);
  CGImageRef convolvedImage = RandomConvolutionCopyOfImage(fullImage);
  CGImageRelease(fullImage);
  return convolvedImage;
}