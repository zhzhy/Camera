#import <QuartzCore/CAEAGLLayer.h>
#import "VideoDisplay.h"
#import "ShaderUtilities.h"
#import "ImageResize.h"

#define YUV420BP 2
#define YUV420P 3
#define VERTEXNUM 4

static const GLfloat squareVertices[] = {
    -1.0f, -1.0f,
    1.0f, -1.0f,
    -1.0f,  1.0f,
    1.0f,  1.0f,
};

static const GLfloat textCoord[] = {
    0.0f, 1.0f,
    1.0f, 1.0f,
    0.0f, 0.0f,
    1.0f, 0.0f,
};

static const GLushort indexVertex[] = {0, 1, 2, 3};

// attributes
static const GLint attribLocation[NUM_ATTRIBUTES] = {
    ATTRIB_VERTEX, ATTRIB_TEXTUREPOSITON,
};

static const GLchar *attribName[NUM_ATTRIBUTES] = {
    "position", "textureCoordinate",
};

static const GLchar *yuv420pName[3] = {
    "SamplerY", "SamplerU", "SamplerV"
};

static const GLchar *yuv420bpName[2] = {
    "SamplerY", "SamplerUV"
};

@implementation VideoDisplay

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (BOOL)bindRenderBuffer
{
    BOOL success = YES;
    
    [oglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &renderBufferWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &renderBufferHeight);
    
    if (frameBufferHandle) {
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorBufferHandle);
        if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
            NSLog(@"Failure with framebuffer generation");
            [self deleteFrameBuffer];
            success = NO;
        }
    }
    
    return success;
}

- (BOOL)createFrameBuffer
{
    BOOL success = YES;
    if (frameBufferHandle) {
        return success;
    }
    
    glDisable(GL_DEPTH_TEST);
    
    glGenFramebuffers(1, &frameBufferHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBufferHandle);
    
    glGenRenderbuffers(1, &colorBufferHandle);
    glBindRenderbuffer(GL_RENDERBUFFER, colorBufferHandle);
    
    success = [self bindRenderBuffer];
    
    return success;
}

- (void)createTexture:(int)texNum
{
    [self deleteTexture];

    glGenTextures(texNum, spriteTexture);
    for (int index = 0; index < texNum; index++) {
        switch (index) {
            case 0:
                glActiveTexture(GL_TEXTURE0);
                glBindTexture(GL_TEXTURE_2D, spriteTexture[index]);
                glTexImage2D(GL_TEXTURE_2D, 0, YinterFormat, videoWidth, videoHeight, 0, YinterFormat, GL_UNSIGNED_BYTE, 0);
                break;
            case 1:
                glActiveTexture(GL_TEXTURE1);
                glBindTexture(GL_TEXTURE_2D, spriteTexture[index]);
                glTexImage2D(GL_TEXTURE_2D, 0, UVinterFormat, halfVideoWidth, halfVideoHeight, 0, UVinterFormat, GL_UNSIGNED_BYTE, 0);
                break;
            case 2:
                glActiveTexture(GL_TEXTURE2);
                glBindTexture(GL_TEXTURE_2D, spriteTexture[index]);
                glTexImage2D(GL_TEXTURE_2D, 0, UVinterFormat, halfVideoWidth, halfVideoHeight, 0, UVinterFormat, GL_UNSIGNED_BYTE, 0);
                break;
        }
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE);
    }
}

- (const GLchar *)loadShader:(NSString *)name
{
    NSString *path;
    const GLchar *source;
    
    path = [[NSBundle mainBundle] pathForResource:name ofType: nil];
    source = (GLchar *)[[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] UTF8String];
    
    return source;
}

- (BOOL)loadShaders:(int)texNum
{
    BOOL success = YES;
    if (texNum != textureNum) {
        glDeleteProgram(yuv420Program);
        yuv420Program = 0;
    }
    if (yuv420Program) {
        return success;
    }
    
    NSString *fileName = nil;
    const GLchar **yuv420Name = nil;
    if (texNum == YUV420P) {
        fileName = @"yuv420p";
        yuv420Name = &yuv420pName[0];
    }else if (texNum == YUV420BP){
        fileName = @"yuv420bp";
        yuv420Name = &yuv420bpName[0];
    }
    
    // Load vertex and fragment shaders
    const GLchar *vertSrc = [self loadShader:[NSString stringWithFormat:@"%@.vsh",fileName,nil]];
    const GLchar *fragSrc = [self loadShader:[NSString stringWithFormat:@"%@.fsh",fileName,nil]];
    
    glueCreateProgram(vertSrc, fragSrc,
                      NUM_ATTRIBUTES, (const GLchar **)&attribName[0], attribLocation,
                      texNum, yuv420Name, yuv420Sample, &yuv420Program);
    
    if (!yuv420Program)
        success = NO;
    
    return success;
}

- (void)freeYUV
{
    free(spriteTexture);
    free(yuv420Sample);
    spriteTexture = nil;
    yuv420Sample = nil;
}

- (BOOL)allocMemoryForYUV:(int)texNum
{
    if (textureNum != texNum) {
        [self freeYUV];
        
        spriteTexture = malloc(sizeof(GLuint) * textureNum);
        yuv420Sample = malloc(sizeof(GLint) * textureNum);
        
        if (texNum == YUV420P) {
            YinterFormat = GL_LUMINANCE;
            UVinterFormat = GL_LUMINANCE;
        }else if (texNum == YUV420BP){
            YinterFormat = GL_RED_EXT;
            UVinterFormat = GL_RG_EXT;
        }
    }
    
    return spriteTexture && yuv420Sample;
}

- (void)setupVertexBufferObject
{
    if (vertexBufferObject[0]) {
        return;
    }
    
    glGenBuffers(VERTEXBUFFEROBJECTNUM, vertexBufferObject);
    
    //bind position vertex buffer object
    glBindBuffer(GL_ARRAY_BUFFER, vertexBufferObject[0]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(squareVertices), squareVertices, GL_STATIC_DRAW);
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, 0);
    
    //bind position texture buffer object
    glBindBuffer(GL_ARRAY_BUFFER, vertexBufferObject[1]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(textCoord), textCoord, GL_STATIC_DRAW);
    glEnableVertexAttribArray(ATTRIB_TEXTUREPOSITON);
    glVertexAttribPointer(ATTRIB_TEXTUREPOSITON, 2, GL_FLOAT, 0, 0, 0);
    
    //bind index buffer object
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vertexBufferObject[2]);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indexVertex), indexVertex, GL_STATIC_DRAW);
    
}

- (BOOL)initializeBuffers:(int)width height:(int)height textureNum:(int)texNum
{
	BOOL success = YES;
    
    videoWidth = width;
    videoHeight = height;
    halfVideoWidth = videoWidth / 2;
    halfVideoHeight = videoHeight / 2;
    Ysize = videoWidth * videoHeight;
    aQuaterYSize = halfVideoWidth * halfVideoHeight;
    
    //alloca memory for yuv sample and texture
    [self allocMemoryForYUV:texNum];
    
    if (![self createFrameBuffer]) {
        success = NO;
    }
    
    [self createTexture:texNum];
    
    if (![self loadShaders:texNum]) {
        success = NO;
    }
    
    //setup vbo
    [self setupVertexBufferObject];
    
    //update texture number
    textureNum = texNum;

    return success;
}

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil) {
		// Use 2x scale factor on Retina displays.
		self.contentScaleFactor = [[UIScreen mainScreen] scale];
        
        // Initialize OpenGL ES 2
        CAEAGLLayer* eaglLayer = (CAEAGLLayer *)self.layer;
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
                                        kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                        nil];
        oglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        if (!oglContext || ![EAGLContext setCurrentContext:oglContext]) {
            NSLog(@"Problem with OpenGL context.");
            [self release];
            
            return nil;
        }
        
        //set pointer to zero
        yuv420Sample = nil;
        spriteTexture = nil;
    }
	
    return self;
}

- (void)layoutSubviews
{
    [self bindRenderBuffer];
}

- (void)renderWithSquareVertices:(const GLfloat*)squareVertices textureVertices:(const GLfloat*)textureVertices
{
    // Use shader program.
    glUseProgram(yuv420Program);
    
    // Update uniform values if there are any
    for (int index = 0; index < textureNum; index++) {
        glUniform1i(yuv420Sample[index], index);
    }
    
    // Validate program before drawing. This is a good check, but only really necessary in a debug build.
    // DEBUG macro must be defined in your debug configurations if that's not already the case.
#if defined(DEBUG)
    if (glueValidateProgram(yuv420Program) == 0) {
        NSLog(@"Failed to validate program: %d", yuv420Program);
        return;
    }
#endif
    
    glDrawElements(GL_TRIANGLE_STRIP, VERTEXNUM, GL_UNSIGNED_SHORT, 0);
    
    // Present
    glBindRenderbuffer(GL_RENDERBUFFER, colorBufferHandle);
    [oglContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)videoKeepOriginalScale
{
    CGFloat videoScale = (CGFloat)videoWidth / videoHeight;
    int newHeight = renderBufferWidth / videoScale;
    int yxalis = (renderBufferHeight - newHeight) / 2;
    glViewport(0, yxalis, renderBufferWidth, newHeight);
}

- (void)videoTileToWholeScreen
{
    glViewport(0, 0, renderBufferWidth, renderBufferHeight);
}

- (void)videoSetToFourWithThree
{
    int newHeight = renderBufferWidth * 0.75f;
    int yxalis = (renderBufferHeight - newHeight) / 2;
    glViewport(0, yxalis, renderBufferWidth, newHeight);
}

- (void)videoSetToSixteenWithNine
{
    int newHeight = renderBufferWidth * 9 / 16;
    int yxalis = (renderBufferHeight - newHeight) / 2;
    glViewport(0, yxalis, renderBufferWidth, newHeight);
}

- (void)displayPixelBuffer:(const UInt8 *)pict width:(int)width height:(int)height
{
    const UInt8 *sampleY;
    const UInt8 *sampleU;
    const UInt8 *sampleV;
    
	if (width != videoWidth || height != videoHeight || textureNum != YUV420P) {
		BOOL success = [self initializeBuffers:(int)width height:(int)height textureNum:YUV420P];
		if ( !success ) {
			NSLog(@"Problem initializing OpenGL buffers.");
            return;
		}
	}
    sampleY = pict;
    sampleU = pict + Ysize;
    sampleV = sampleU + aQuaterYSize;
    
    for (int index = 0; index < textureNum; index++) {
        switch (index) {
            case 0:
                glActiveTexture(GL_TEXTURE0);
                glBindTexture(GL_TEXTURE_2D, spriteTexture[index]);
                glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, videoWidth, videoHeight, YinterFormat, GL_UNSIGNED_BYTE, sampleY);
                break;
            case 1:
                glActiveTexture(GL_TEXTURE1);
                glBindTexture(GL_TEXTURE_2D, spriteTexture[index]);
                glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, halfVideoWidth, halfVideoHeight, UVinterFormat, GL_UNSIGNED_BYTE, sampleU);
                break;
            case 2:
                glActiveTexture(GL_TEXTURE2);
                glBindTexture(GL_TEXTURE_2D, spriteTexture[index]);
                glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, halfVideoWidth, halfVideoHeight, UVinterFormat, GL_UNSIGNED_BYTE, sampleV);
                break;
        }
    }
    
    // Set texture parameters
    glBindFramebuffer(GL_FRAMEBUFFER, frameBufferHandle);
    
    // Set the view port to the view
    [self videoTileToWholeScreen];
    
    // Draw the texture on the screen with OpenGL ES 2
    [self renderWithSquareVertices:squareVertices textureVertices:textCoord];
}

- (void)displayImageBuffer:(CVImageBufferRef)imageBuffer
{
    size_t width = CVPixelBufferGetWidthOfPlane(imageBuffer, 0);
    size_t height = CVPixelBufferGetHeightOfPlane(imageBuffer, 0);
    if (width != videoWidth || height != videoHeight || textureNum != YUV420BP) {
        BOOL success = [self initializeBuffers:width height:height textureNum:YUV420BP];
        if (!success) {
            NSLog(@"initialize opengl failure!");
            return;
        }
    }
    
    CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, spriteTexture[0]);
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, videoWidth, videoHeight, YinterFormat, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0));
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, spriteTexture[1]);
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, halfVideoWidth, halfVideoHeight, UVinterFormat, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1));
    CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    
    // Set texture parameters
    glBindFramebuffer(GL_FRAMEBUFFER, frameBufferHandle);
    
    // Set the view port to the view
    [self videoTileToWholeScreen];
	
    // Draw the texture on the screen with OpenGL ES 2
    [self renderWithSquareVertices:squareVertices textureVertices:textCoord];
}

- (void)deleteTexture
{	
    glDeleteTextures(textureNum, spriteTexture);
    memset(spriteTexture, 0, sizeof(GLuint) * textureNum);
}

- (void)deleteFrameBuffer
{
    if (frameBufferHandle) {
        glDeleteFramebuffers(1, &frameBufferHandle);
        frameBufferHandle = 0;
    }
	
    if (colorBufferHandle) {
        glDeleteRenderbuffers(1, &colorBufferHandle);
        colorBufferHandle = 0;
    }
}

- (void)deleteVertexBufferObject
{
    glDeleteBuffers(VERTEXBUFFEROBJECTNUM, vertexBufferObject);
    memset(vertexBufferObject, 0, sizeof(vertexBufferObject));
}

- (void)dealloc
{
    if (yuv420Program) {
        glDeleteProgram(yuv420Program);
        yuv420Program = 0;
    }
    [self deleteFrameBuffer];
    [self deleteVertexBufferObject];
    [self deleteTexture];
    [self freeYUV];
    
    [super dealloc];
}

@end
