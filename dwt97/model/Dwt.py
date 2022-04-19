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
    def __init__(self, dir = "row", type = "forward", bufferSize = 1):

        if (type != "forward" and type != "backward"):
            raise Exception("type must be 'forward' or 'backward'")

        if (dir != "row" and dir != "col"):
            raise Exception("dir must be 'row' or 'col'")

        self._dir = dir
        self._type = type
        consts = Constants()

        self._firUnit = ProcessorUnit(
            1/consts.alpha, 
            1/(consts.alpha * consts.beta) + 1, 
            bufferSize)
        self._secUnit = ProcessorUnit(
            1/(consts.gama * consts.beta), 
            1/(consts.gama * consts.delta) + 1, 
            bufferSize)

        self._kHigh = consts.alpha * consts.beta * consts.gama / consts.k
        self._kLow = consts.alpha * consts.beta * consts.gama * consts.delta * consts.k

        self._firInvUnit = ProcessorUnit(
            1./(consts.idelta * consts.k * consts.k), 
            1/(consts.idelta * consts.igama) + 1, 
            bufferSize)
        self._secInvUnit = ProcessorUnit(
            1/(consts.igama * consts.ibeta), 
            1/(consts.ialpha * consts.ibeta) + 1, 
            bufferSize)
        self._ikEven = consts.ialpha * consts.ibeta * consts.igama * consts.idelta * consts.k
        self._ikOdd = consts.ibeta * consts.igama * consts.idelta * consts.k

    def __call__(self, inputMatrix : np.array):
        matrix = self.__ExpandBorders(inputMatrix)
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


        if (self._type == "forward"):
            if (self._dir == "row"):
                matrix = matrix[:, 8:]
            elif (self._dir == "col"):
                matrix = matrix[8:, :]
        elif (self._type == "backward"):
            if (self._dir == "row"):
                matrix = matrix[:, 9:-1]
            elif (self._dir == "col"):
                matrix = matrix[9:-1, :]

        return matrix

    def __ExpandBorders(self, inputMatrix: np.array):
        matrix = np.array(inputMatrix)
        expandSize = 0
        if (self._type == "forward"):
            expandSize = 4
        elif (self._type == "backward"):
            expandSize = 5

        if (self._dir == "row"):
            matrix = np.pad(matrix, expandSize, 'reflect')[expandSize:-expandSize, :]
        elif (self._dir == "col"):
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

class Dwt2D():
    def __init__(self, type = "forward", rowSize = 1):
        pass

    def __call__(self, matrix : np.array):
        pass

    def Transpose(self, matrix : np.array):
        newMatrix = np.zeros(matrix.shape)
        (y, x) = newMatrix.shape

        for row in range(0, y, 2):
            for col in range(0, x, 2):
                m = matrix[row:row+2, col:col+2]
                newMatrix[row:row+2, col:col+2] = m.T

        return newMatrix        

    def Reorder(self, matrix : np.array):
        newMatrix = np.array(matrix)
        (y, x) = newMatrix.shape

        for row in range(y):
            newMatrix[row, :] = np.concatenate((newMatrix[row, 0::2], newMatrix[row, 1::2]), axis=0)

        for col in range(x):
            newMatrix[:, col] = np.concatenate((newMatrix[0::2, col], newMatrix[1::2, col]), axis=0)

        return newMatrix