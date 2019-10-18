import numpy as np
from Codec import ShiftCodec, DCTCodec, QuantizationCodec
from itertools import product

class CompressionCodecs:
    '''
    A composite of codecs for Image Compression.
    
    User may specify the order of CODEC component
    through constructor method, but an Image 
    Compression Codecs typicall is made up of 
    3 codecs -- Shift, DTC, Quantization.
    '''
    def __init__(self, codecs=None, **kw):
        '''
        Constructor method for CompressionCodecs.
        
        Arguments:
            codecs -- sequence of CODEC subclass used
                in both ENCODING and DECODING. 
                If it is None, it would default to 
                [ShiftCodec, DCTCodec, QuantizationCodec].
            kw -- arguments passed along to each CODEC.
        '''
        if codecs is None:
            codecs = [ShiftCodec, DCTCodec, QuantizationCodec]
        self.codecs = [codec(**kw) for codec in codecs]

        
    def __reshape(self, x):
        '''
        Reshape x into a three dimensional array 
        if x is a two dimensional array.
        '''
        if len(x.shape) == 2:
            x = np.reshape(x, [x.shape[0], x.shape[1], 1])
        return x
    
    def __reshape_back(self, x):
        '''
        Reshape x back into two dimensional if x has
        only one channel.
        '''
        if x.shape[2]==1:
            x = np.squeeze(x, 2)
        return x
    
    def compress(self, x):
        '''
        Compress x through encoding and decoding each 
        8 by 8 block in the image.
        
        Arguments:
        x -- an image in the format of either a two 
        dimensional uint8 array (grayscale image) or 
        three dimensional uint8 array (RGB image).
        '''
        # Reshape x into three dimensional if x is a 
        # two dimensional array.
        x = self.__reshape(x)
        # Crop x to multiply of 8 in width and height.
        x = self.__crop8(x)
        # Convert x into float64 format.
        x = x.astype(np.float64)
        # Get (height, width, channel) of x.
        height = x.shape[0]
        width = x.shape[1]
        channel = x.shape[2]
        # Iterate through each 8 by 8 block in x.
        bp = product(range(0, height, 8), range(0, width, 8), range(channel))
        for (i, j, p) in bp:
            # Encode and decode each block and place it back.
            x[i:i+8, j:j+8, p] = self.decode(self.encode(x[i:i+8, j:j+8, p]))
        # Clip x into range [0, 255] and convert it to uint8.
        x = np.clip(x, 0, 255).astype(np.uint8)
        # Reshape x back into two dimensional if x has
        # only one channel.
        x = self.__reshape_back(x)
        return x
            
    def __crop8(self, x):
        '''
        Crop x to multiply of 8 in both width and 
        height.
        '''
        nearest8 = lambda y: int(y/8)*8
        return x[:nearest8(x.shape[0]), :nearest8(x.shape[1]), :]
    
    def encode(self, x):
        '''Encode x in the order of CODECS.'''
        for codec in self.codecs:
            x = codec.encode(x)
        return x
    
    def decode(self, x):
        '''
        Encode x in the inverse order of CODECS.
        '''
        for codec in self.codecs[::-1]:
            x = codec.decode(x)
        return x
