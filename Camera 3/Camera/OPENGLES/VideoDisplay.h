#import <UIKit/UIKit.h>

enum{
    ATTRIB_VERTEX,
    ATTRIB_TEXTUREPOSITON,
    NUM_ATTRIBUTES
};

#define VERTEXBUFFEROBJECTNUM (NUM_ATTRIBUTES + 1)

@interface VideoDisplay : UIView 
{    
	EAGLContext* oglContext;
	GLuint frameBufferHandle;
	GLuint colorBufferHandle;
    GLuint *spriteTexture;
    GLint *yuv420Sample;
    GLuint yuv420Program;
    
    //vbo target
    GLuint vertexBufferObject[VERTEXBUFFEROBJECTNUM];
    
    int renderBufferWidth;
	int renderBufferHeight;
    int videoWidth;
    int videoHeight;
    int halfVideoWidth;
    int halfVideoHeight;
    int Ysize;
    int aQuaterYSize;
    
    GLint YinterFormat;
    GLint UVinterFormat;
    int textureNum;
}

- (void)displayPixelBuffer:(const UInt8 *)pict width:(int)width height:(int)height;
- (void)displayImageBuffer:(CVImageBufferRef)imageBuffer;
@end



