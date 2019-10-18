from abc import ABC, abstractmethod
import numpy as np
from scipy import fftpack

class Codec(ABC):
    '''
    Codec is an abstract class which every 
    CODEC (Shift, DCT, Quantization, etc.) 
    class is derived from.
    
    A subclass of Codec should implement
    both ENCODE and DECODE method. Otherwise,
    an error would be raised.
    '''
    def __init__(self, **kw):
        '''Construct method for CODEC.'''
        pass
    
    @abstractmethod
    def encode(self, x):
        '''An abstract method for encoding.'''
        pass
    
    @abstractmethod
    def decode(self, x):
        '''An abstract method for decoding.'''
        pass
    
class ShiftCodec(Codec):
    '''
    Codec for shifting.
    
    Given an input x in shape (8, 8), the codec 
    would do the following.
    ENCODING:
        Subtract 128 for each element in x.
    DECODING:
        Add 128 for each element in x.
    '''
    def encode(self, x):
        '''Shift ENCODING.'''
        return x - 128
    
    def decode(self, x):
        '''Shift DECODING.'''
        return x + 128

class DCTCodec(Codec):
    '''
    Codec for Discrete Cosine Transform (DCT).
    
    Given an input x in shape (8, 8), the codec 
    would do the following.
    ENCODING:
        On input f, calculate and return F using the 
        equation.
        F(u, v) = 
            1/4 * C(u) * C(v) * sum_{x=0}^7 sum_{y=0}^7 {
                f(x, y) * 
                cos((2*x+1)*u*pi/16) * 
                cos((2*y+1)*v*pi/16)
            }
        where C(u), C(v) = 1/sqrt(2) for u, v = 0;
            C(u), C(v) = 1 otherwise.
    DECODING:
        On input F, calculate and return f using the 
        equation.
        f(x, y) = 
            1/4 *  sum_{u=0}^7 sum_{v=0}^7 {
                C(u) * C(v) *
                F(u, v) * 
                cos((2*x+1)*u*pi/16) * 
                cos((2*y+1)*v*pi/16)
            }
        where C(u), C(v) = 1/sqrt(2) for u, v = 0;
            C(u), C(v) = 1 otherwise.
    '''
    def __init__(self, **kw):
        '''
        Construct method for DCT Codec. 
        
        To achieve higher efficiency during both encoding 
        and decoding, the process of DCT encoding and 
        decoding is transformed into matrix multiplication.
        During each process, a pre-computed encode matrix 
        (encodeMatrix) and a decode matrix (decodeMatrix) 
        will be used.
        
        encodeMatrix = 
            cos(pi/16 *
                    [[  0,   0,   0,   0,   0,   0,   0,   0],
                     [  1,   3,   5,   7,   9,  11,  13,  15],
                     [  2,   6,  10,  14,  18,  22,  26,  30],
                     [  3,   9,  15,  21,  27,  33,  39,  45],
                     [  4,  12,  20,  28,  36,  44,  52,  60],
                     [  5,  15,  25,  35,  45,  55,  65,  75],
                     [  6,  18,  30,  42,  54,  66,  78,  90],
                     [  7,  21,  35,  49,  63,  77,  91, 105]]
            )
        
        decodeMatrix = 
            cos(pi/16 *
                    [[  0,   1,   2,   3,   4,   5,   6,   7],
                     [  0,   3,   6,   9,  12,  15,  18,  21],
                     [  0,   5,  10,  15,  20,  25,  30,  35],
                     [  0,   7,  14,  21,  28,  35,  42,  49],
                     [  0,   9,  18,  27,  36,  45,  54,  63],
                     [  0,  11,  22,  33,  44,  55,  66,  77],
                     [  0,  13,  26,  39,  52,  65,  78,  91],
                     [  0,  15,  30,  45,  60,  75,  90, 105]]
            )
        '''
        range8 = np.arange(8).reshape([8, 1])
        self.encodeMatrix = np.cos(range8 @ (2*range8.T+1) * np.pi / 16)
        self.decodeMatrix = np.cos((2*range8+1) @ range8.T * np.pi / 16)
        self.C = np.array([[1/np.sqrt(2)] + 7*[1]], np.float64)
        self.C = self.C.T @ self.C
        
    def encode(self, x):
        '''Efficient DCT ENCODING using pre-computed encodeMatrix.'''
        return 1/4 * self.C * (self.encodeMatrix @ x @ self.encodeMatrix.T)
    
    def decode(self, x):
        '''Efficient DCT DECODING using pre-computed encodeMatrix.'''
        return 1/4 * (self.decodeMatrix @ (self.C * x) @ self.decodeMatrix.T)


class QuantizationCodec(Codec):
    '''
    Codec for Quantization.
    
    Given an input x in shape (8, 8), the codec 
    would do the following.
    ENCODING:
        On input F, calculate and return FQ using
        the equation.
        FQ(u, v) = Integer Round(F(u, v) / Q(u, v))
        where Q is the quantization table.
    DECODING:
        On input FQ, calculate and return F using
        the equation.
        F(u, v) = FQ(u, v) * Q(u, v)
        where Q is the quantization table.
    '''
    def __init__(self, k, qTable, **kw):
        '''
        Construct method for Quantization Codec.
        
        Arguement:
        k -- the multiplier to the default 
            quantization table.
        qTable -- the default quantization table (Q).
        
        The actual quantization table used during
        encoding and decoding would be 
            Integer Round(k * qTable).
        '''
        self.qTable = np.around(k * qTable)
    
    def encode(self, x):
        '''Quantization ENCODING.'''
        return np.around(x / self.qTable)
    
    def decode(self, x):
        '''Quantization DECODING.'''
        return np.around(x * self.qTable)
