//
//  Class to analyize and detect screams from the inputted audio data
//

#pragma once

#include "FftMgr.h"
#include <vector>

typedef void (*LPFUNC_RECORDING)(void*, int, int);

class CDetectMgr
{
public:
	CDetectMgr(int p_nSamplingFreq);
	~CDetectMgr(void);
    
    /*
     * Process the input data from microphone to detect
     */
	bool Process(float* p_fData, int p_nFrameLen, int &p_nAlarmType, int &p_nAlarmIdx);
    
    /*
     * Clear fft variables cleanly.
     */
	void ClearFftValues();
    
    /*
     * Check with escalation time
     */
    bool CheckWithEscalationTime();
    
private:

    /*
     * Reset universal engine's variables
     */
    void ResetFrameInfo();

private:
    // Engine variables for FFT
	FftMgr* fft;

	int minIdx;
	int maxIdx;

	int m_nDetectedFrames;
    
    /** Universal Engine Varaibles */
    int m_nUnivEngineFrameCnt;
    int m_nUnivEngineInvalidCnt;
    int m_nUnivEngineRepeatCnt;
    
    /** Noising environment deciding varaibles */
    int m_nNoiseSeqFrameCnt;
    int m_nNormalSeqFrameCnt;
    bool m_bInNoiseEnvironment;
    
    /** Instability check */
    float *m_maxFreqs;
    bool m_bInstability;
    
    /** Max Volumes per frame */
    float *m_maxVolumesPerFrame;
    int m_nMaxVolPos;
};

