import numpy as np

class Constants():
    def __init__(self):
        self.alpha  = -1.586134342
        self.beta   = -0.052980118
        self.gama   =  0.882911076
        self.delta  =  0.443506852
        self.k      =  1.149604398
        self.ialpha =  1.586134342
        self.ibeta  =  0.052980118
        self.igama  = -0.882911076
        self.idelta = -0.443506852

class Pair():
    def __init__(self, even, odd):
        self.even = even
        self.odd = odd

class ProcessorUnit():
    def __init__(self, kOdd, kEven, bufferSize):
        self._kOdd = kOdd
        self._kEven = kEven
        self._bufferSize = bufferSize
        self._evenBuffer = np.zeros(bufferSize)
        self._oddBuffer = np.zeros(bufferSize)
        self._writeIdx = 0

    def __NextWriteIdx(self):
        self._writeIdx = (self._writeIdx + 1) % self._bufferSize

    def __call__(self, pair : Pair):
        output = Pair(0, 0)

        kxe = pair.even * self._kEven
        kxo = pair.odd * self._kOdd

        toOddBuff = pair.even + kxo
        fromOddBuff = self._oddBuffer[self._writeIdx]
        fromEvenBuff = self._evenBuffer[self._writeIdx]
        toEvenBuff = fromOddBuff + kxe

        self._evenBuffer[self._writeIdx] = toEvenBuff
        self._oddBuffer[self._writeIdx] = toOddBuff

        self.__NextWriteIdx()

        output.odd = fromOddBuff + pair.even
        output.even = output.odd + fromEvenBuff
 
        return output

class Dwt1D():
    def __init__(self, dir = "row", type = "forward", bufferSize = 1, 
                 outputScale=True, expand="leftRight", transposeAfterExpand=False,
                 inputTranspose=False, transposeBeforeCrop=False, outputCrop=True):

        if (expand != "leftRight" and expand != "upDown"):
            raise Exception("expand must be 'forward' or 'backward'")

        if (type != "forward" and type != "backward"):
            raise Exception("type must be 'forward' or 'backward'")

        if (dir != "row" and dir != "col"):
            raise Exception("dir must be 'row' or 'col'")

        self._expand = expand
        self._dir = dir
        self._type = type
        self._transposeAfterExpand = transposeAfterExpand
        self._inputTranspose = inputTranspose
        self._transposeBeforeCrop = transposeBeforeCrop
        self._outputCrop = outputCrop

        consts = Constants()

        self._firUnit = ProcessorUnit(
            1/consts.alpha, 
            1/(consts.alpha * consts.beta) + 1, 
            bufferSize)
        self._secUnit = ProcessorUnit(
            1/(consts.gama * consts.beta), 
            1/(consts.gama * consts.delta) + 1, 
            bufferSize)

        if (outputScale):
            self._kHigh = consts.alpha * consts.beta * consts.gama / consts.k
            self._kLow = consts.alpha * consts.beta * consts.gama * consts.delta * consts.k
        else:
            self._kHigh = 1.0
            self._kLow = 1.0

        self._firInvUnit = ProcessorUnit(
            1./(consts.idelta * consts.k * consts.k), 
            1/(consts.idelta * consts.igama) + 1, 
            bufferSize)
        self._secInvUnit = ProcessorUnit(
            1/(consts.igama * consts.ibeta), 
            1/(consts.ialpha * consts.ibeta) + 1, 
            bufferSize)

        if (outputScale):
            self._ikEven = consts.ialpha * consts.ibeta * consts.igama * consts.idelta * consts.k
            self._ikOdd = consts.ibeta * consts.igama * consts.idelta * consts.k
        else:
            self._ikEven = 1.0
            self._ikOdd = 1.0


    def __call__(self, inputMatrix : np.array):
        matrix = np.array(inputMatrix)
        if (self._inputTranspose):
            matrix = self.Transpose(matrix)
        matrix = self.__ExpandBorders(matrix)
        if (self._transposeAfterExpand):
            matrix = self.Transpose(matrix)
        (y, x) = matrix.shape


        if (self._dir == "row"):
            rowRange = range(y)
            colRange = range(0, x, 2)
        else:
            rowRange = range(0, y, 2)
            colRange = range(x)


        for row in rowRange:
            for col in colRange:
                input = None
                if (self._dir == "row"):
                    input = Pair(matrix[row, col], matrix[row, col+1])
                    output = self.__CalculateStep(input)
                    matrix[row, col] = output.even
                    matrix[row, col+1] = output.odd
                else:
                    input = Pair(matrix[row, col], matrix[row+1, col])
                    output = self.__CalculateStep(input)
                    matrix[row, col] = output.even
                    matrix[row+1, col] = output.odd

        if (self._transposeBeforeCrop):
            matrix = self.Transpose(matrix)

        if (self._outputCrop):
            if (self._type == "forward"):
                if (self._expand == "leftRight"):
                    matrix = matrix[:, 8:]
                elif (self._expand == "upDown"):
                    matrix = matrix[8:, :]
            elif (self._type == "backward"):
                if (self._expand == "leftRight"):
                    matrix = matrix[:, 9:-1]
                elif (self._expand == "upDown"):
                    matrix = matrix[9:-1, :]

        return matrix

    def __ExpandBorders(self, inputMatrix: np.array):
        matrix = np.array(inputMatrix)
        expandSize = 0
        if (self._type == "forward"):
            expandSize = 4
        elif (self._type == "backward"):
            expandSize = 5

        if (self._expand == "leftRight"):
            matrix = np.pad(matrix, expandSize, 'reflect')[expandSize:-expandSize, :]
        elif (self._expand == "upDown"):
            matrix = np.pad(matrix, expandSize, 'reflect')[:, expandSize:-expandSize]

        return matrix

    def __CalculateStep(self, pair : Pair):
        output = None
        if (self._type == "forward"):
            output = self._firUnit(pair)
            output = self._secUnit(output)
            output.even = output.even * self._kLow
            output.odd = output.odd * self._kHigh
        elif (self._type == "backward"):
            output = self._firInvUnit(pair)
            output = self._secInvUnit(output)
            output.even = output.even * self._ikEven
            output.odd = output.odd * self._ikOdd

        return output

    def Transpose(self, matrix : np.array):
        newMatrix = np.zeros(matrix.shape)
        (y, x) = newMatrix.shape

        for row in range(0, y, 2):
            for col in range(0, x, 2):
                m = matrix[row:row+2, col:col+2]
                newMatrix[row:row+2, col:col+2] = m.T

        return newMatrix    

class Dwt2D():
    def __init__(self, type = "forward", lineSize = 512, scaleOnFinalStage=False):
        self._scaleOnFinalStage = scaleOnFinalStage
        consts = Constants()
        self._kLL = consts.alpha * consts.alpha   \
                    * consts.beta * consts.beta   \
                    * consts.gama * consts.gama   \
                    * consts.delta * consts.delta \
                    * consts.k * consts.k
        self._kLH = consts.alpha * consts.alpha \
                    * consts.beta * consts.beta \
                    * consts.gama * consts.gama \
                    * consts.delta
        self._kHH = consts.alpha * consts.alpha \
                    * consts.beta * consts.beta \
                    * consts.gama * consts.gama \
                    / (consts.k * consts.k)
        self._kHL = self._kLH

        # print(self._kLL, self._kHH, self._kHL)
        
        forwardOutputScale1D = not scaleOnFinalStage
        backwardOutputScale1D = True
        
        self._type = type

        self._dwtCol  = Dwt1D(dir = 'col', outputScale=forwardOutputScale1D, bufferSize=lineSize, expand='upDown')
        self._dwtRow  = Dwt1D(dir = 'col', outputScale=forwardOutputScale1D, bufferSize=2, expand='leftRight', transposeAfterExpand=True)
        
        self._idwtRow = Dwt1D(dir = 'col', outputScale=backwardOutputScale1D, bufferSize=2, expand='leftRight', type='backward', 
                        transposeAfterExpand=True, inputTranspose=True, transposeBeforeCrop=True)        
        self._idwtCol = Dwt1D(dir = 'col', outputScale=backwardOutputScale1D, type='backward', bufferSize=lineSize, expand='upDown')


    def __call__(self, matrix : np.array):
        input = np.array(matrix)
        if (self._type != "forward"):
            input = self.IReorder(input)

        if (self._type == "forward"):
            colCoeff = self._dwtCol(input)
            output = self._dwtRow(colCoeff)
        else:
            colCoeff = self._idwtRow(input)
            output = self._idwtCol(colCoeff)

        if (self._scaleOnFinalStage):
            (h, w) = output.shape
            k = np.array(((self._kLL, self._kLH), (self._kHL, self._kHH)))
            k = np.tile(k, (h//2, w//2))
            output = np.multiply(k, output)

        if (self._type == "forward"):
            output = self.Reorder(output)

        return output

    def Reorder(self, matrix : np.array):
        newMatrix = np.array(matrix)
        (y, x) = newMatrix.shape

        for row in range(y):
            newMatrix[row, :] = np.concatenate((newMatrix[row, 0::2], newMatrix[row, 1::2]), axis=0)

        for col in range(x):
            newMatrix[:, col] = np.concatenate((newMatrix[0::2, col], newMatrix[1::2, col]), axis=0)

        return newMatrix

    def IReorder(self, matrix : np.array):
        newMatrix = np.array(matrix)
        tmpMatrix = np.array(newMatrix)
        (y, x) = newMatrix.shape

        for i in range(x):
            if (i % 2):
                idx = i//2 + x//2
            else:
                idx = i//2
            tmpMatrix[:, i] = matrix[:, idx]

        for i in range(y):
            if (i % 2):
                idx = i//2 + x//2
            else:
                idx = i//2
            newMatrix[i, :] = tmpMatrix[idx, :]

        return newMatrix
