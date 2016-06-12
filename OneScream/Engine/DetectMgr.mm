//
//  Class to analyize and detect screams from the inputted audio data
//

#include "DetectMgr.h"
#include "globals.h"
#import <math.h>
#import <stdio.h>

using namespace std;

// min frequency to represent graphically
const float minFreqToDraw = 400;
// max frequency to represent
const float maxFreqToDraw = 5000;

const int MAX_GROUP_CNT = 2000;

const int MAX_FREQ_CNT = 10;
const float fDeltaThreshold = 0.1f;

const int MAX_VOLUME_CNT = 30;

const bool isTesting = true;

CDetectMgr::CDetectMgr(int p_nSamplingFreq)
{
    if (MAX_FREQS_CNT_TO_CHECK <= 0) {
        MAX_FREQS_CNT_TO_CHECK = 1;
    }
    
	fft = new FftMgr(FRAME_LEN, (float)p_nSamplingFreq); //m_wavReader.m_Info.SamplingFreq

	minIdx = fft->freqToIndex(minFreqToDraw);
	maxIdx = fft->freqToIndex(maxFreqToDraw);

	m_nDetectedFrames = 0;
    
    m_maxFreqs = new float[MAX_FREQS_CNT_TO_CHECK];
    
    m_maxVolumesPerFrame = new float[MAX_VOLUME_CNT];
    
    ResetFrameInfo();
    
    m_nNoiseSeqFrameCnt = 0;
    m_nNoiseSeqFrameCnt = 0;
    m_bInNoiseEnvironment = false;
    
    
    // test
    if (isTesting) {
        SCREAM_ROUGHNESS = 350;
        MAX_FREQS_CNT_TO_CHECK = 1;
        COUNTING_SCREAMS = 2;
        SCREAM_INSTABILITY_BANDWIDTH = -1;
    }

}


CDetectMgr::~CDetectMgr(void)
{
	ClearFftValues();
	delete fft;
    
    delete m_maxVolumesPerFrame;
    
    delete m_maxFreqs;
}

void CDetectMgr::ResetFrameInfo()
{
    m_nUnivEngineFrameCnt = 0;
    m_nUnivEngineInvalidCnt = 0;
    m_nUnivEngineRepeatCnt = 0;
    
    for (int i = 0; i < MAX_FREQS_CNT_TO_CHECK; i++) {
        m_maxFreqs[i] = 0;
    }
    
    for (int i = 0; i < MAX_VOLUME_CNT; i++) {
        m_maxVolumesPerFrame[i] = 0;
    }
    m_nMaxVolPos = 0;
}

void CDetectMgr::ClearFftValues()
{

	m_nDetectedFrames = 0;
}

bool CDetectMgr::Process(float* p_fData, int p_nFrameLen, int &p_nAlarmType, int &p_nAlarmIdx)
{
    float fMaxVals[MAX_FREQ_CNT] = {0.0f};
    float fMaxFreqs[MAX_FREQ_CNT] = {0.0f};
    
    float val = 0.0f;
    float prevVal = 0.0f;
    float dist = 0.0f;
    float preDist = 0.0f;

    int idx = 0;
    
    if (g_bPaused)
        return false;
    
    float fMaxVolume = p_fData[0];
    for (int i = 1; i < FRAME_LEN; i++) {
        if (fMaxVolume < p_fData[i]) {
            fMaxVolume = p_fData[i];
        }
    }
    m_maxVolumesPerFrame[m_nMaxVolPos] = fMaxVolume;
    m_nMaxVolPos = (m_nMaxVolPos + 1) % MAX_VOLUME_CNT;
    
    // convert inputted data form mic to FFT values
    p_fData[0] = 0;
	fft->forward(p_fData, FRAME_LEN);
    
    // format engine variables to process
    for (int i = 0; i < MAX_FREQ_CNT; i++)
    {
        fMaxVals[i] = 0.0f;
        fMaxFreqs[i] = 0.0f;
    }
    
    // get 10 maximum amplitudes and their frequencies
    for (int i = minIdx; i <= maxIdx; i++)
    {
        val = fft->getBand(i);
        
        dist = val - prevVal;
        if (preDist > 0 && dist < 0)
        {
            if (prevVal > fDeltaThreshold)
            {
                idx = 0;
                for (; idx < MAX_FREQ_CNT; idx++)
                {
                    if (fMaxVals[idx]==0 || prevVal > fMaxVals[idx])
                        break;
                }
                
                float fFreq = fft->indexToFreq(i - 1);
                if (idx < MAX_FREQ_CNT)
                {
                    for (int j = MAX_FREQ_CNT - 1; j > idx; j--)
                    {
                        if (fMaxVals[j-1] == 0)
                            continue;
                        fMaxVals[j] = fMaxVals[j-1];
                        fMaxFreqs[j] = fMaxFreqs[j-1];
                    }
                    fMaxVals[idx] = prevVal;
                    fMaxFreqs[idx] = fFreq;
                }
            }
        }
        
        preDist = dist;
        prevVal = val;
    }
    
    val = log10f(fMaxVals[0]);
    
	bool bDetected = false;

	if (m_nDetectedFrames > 0) 
	{
		m_nDetectedFrames--;
		return bDetected;
	}
    
    // Checking Noise Environment
    float evalutation_val = fMaxVals[0];
    if (evalutation_val > BACKGROUND_NOISE_ROUGHNESS) {
        m_nNoiseSeqFrameCnt++;
        m_nNormalSeqFrameCnt = 0;
    } else {
        m_nNormalSeqFrameCnt++;
        m_nNoiseSeqFrameCnt = 0;
    }
    
    if (!m_bInNoiseEnvironment) {
        if (m_nNoiseSeqFrameCnt >= CONTINUES_BACKGROUND_NOISE_TIME) {
            // noise environment is checked
            m_bInNoiseEnvironment = true;
        }
    } else {
        if (m_nNormalSeqFrameCnt >= CONTINUES_BACKGROUND_NOISE_TIME) {
            // current environment becomes ok
            m_bInNoiseEnvironment = false;
        }
    }
    
    if (m_bInNoiseEnvironment) {
        return false;
    }

    printf("bDetected=%d       maxFreq=%f         maxVal=%f\n\n                  maxFreq2=%f        maxVal2=%f\n\n                  m_nUnivEngineFrameCnt=%d  m_nUnivEngineRepeatCnt=%d   m_nUnivEngineInvalidCnt=%d\n\n\n",
           bDetected ? 1 : 0, fMaxFreqs[0], fMaxVals[0], fMaxFreqs[1], fMaxVals[2], m_nUnivEngineFrameCnt, m_nUnivEngineRepeatCnt, m_nUnivEngineInvalidCnt);
    
    
    // Universal Engine to detect one scream
    int nThreshold = SCREAM_ROUGHNESS + SCREAM_ROUGHNESS_DELTA;
    if(!bDetected){
        bool bCandidate = true;
        
        for (int i = 0; i < MAX_FREQS_CNT_TO_CHECK; i++) {
            if (!(fMaxFreqs[i] >= SCREAM_FREQ_MIN && fMaxFreqs[i] <= SCREAM_FREQ_MAX
                && fMaxVals[i] >= nThreshold)) {
                
                bCandidate = false;
                break;
            }
        }

        if (bCandidate)
        {
            m_nUnivEngineInvalidCnt = 0;
            
            // check instability of Top Frequencies
            float tmpMaxFreq[MAX_FREQS_CNT_TO_CHECK];
            for (int i = 0; i < MAX_FREQS_CNT_TO_CHECK; i++) {
                tmpMaxFreq[i] = fMaxFreqs[i];
            }
            
            for (int i = 0; i < MAX_FREQS_CNT_TO_CHECK - 1; i++) {
                for (int j = i+1; j < MAX_FREQS_CNT_TO_CHECK; j++) {
                    float fTemp = tmpMaxFreq[i];
                    tmpMaxFreq[i] = tmpMaxFreq[j];
                    tmpMaxFreq[j] = fTemp;
                }
            }
            
            if (m_nUnivEngineFrameCnt > 0) {
                bool bInstable = true;
                for (int i = 0; i < MAX_FREQS_CNT_TO_CHECK; i++) {
                    if (fabs(tmpMaxFreq[i] - m_maxFreqs[i]) < SCREAM_INSTABILITY_BANDWIDTH) {
                        bInstable = false;
                    }
                    
                    m_maxFreqs[i] = tmpMaxFreq[i];
                }
                
                if (bInstable) {
                    m_bInstability = true;
                }
            } else {
                m_bInstability = false;
            }
            
            m_nUnivEngineFrameCnt++;
            if (m_nUnivEngineFrameCnt == SCREAM_SOUND_TIME_MIN)
            {
                m_nUnivEngineRepeatCnt++;
                if (m_nUnivEngineRepeatCnt >= COUNTING_SCREAMS)
                {
                    if (m_bInstability || SCREAM_INSTABILITY_BANDWIDTH <= 0) {
                        bDetected = true;
                        p_nAlarmType = -1;
                        p_nAlarmIdx = 0;
                    }
                }
            }
            else if (m_nUnivEngineFrameCnt >= SCREAM_SOUND_TIME_MAX) {
                m_nUnivEngineRepeatCnt = 0;
            }
/*            else if (m_nUnivEngineFrameCnt == UNIVERSAL_DETECT_PERIOD_FRAMES)
            {
                bDetected = true;
                p_nAlarmType = -1;
                p_nAlarmIdx = 0;
            }
 */
        } else {
            m_nUnivEngineInvalidCnt++;
            if (m_nUnivEngineInvalidCnt >= SCREAM_BREATH_TIME_MIN && m_nUnivEngineFrameCnt > 0)
            {
                m_nUnivEngineFrameCnt = 0;
                
                if (!m_bInstability || !CheckWithEscalationTime()) {
                    m_nUnivEngineRepeatCnt = 0;
                }
                
                m_bInstability = false;
            }
            
            if (m_nUnivEngineInvalidCnt > SCREAM_BREATH_TIME_MAX && m_nUnivEngineRepeatCnt > 0)
            {
                m_nUnivEngineRepeatCnt = 0;
            }
        }
    }
    
	if (bDetected)
	{
        // when scream is detected
        ResetFrameInfo();
		m_nDetectedFrames = 15;
	}
	
	return bDetected;
}

bool CDetectMgr::CheckWithEscalationTime() {
    if (isTesting)
        return true;
    
    int thresholdIndex = 0;
    float minPosArray[MAX_VOLUME_CNT] = {0};
    int minPosArrayCnt = 0;
    float maxPosArray[MAX_VOLUME_CNT] = {0};
    int maxPosArrayCnt = 0;
    
    int nStartPos = m_nMaxVolPos;
    bool bPrevIsInc = m_maxVolumesPerFrame[(nStartPos + 1) % MAX_VOLUME_CNT] > m_maxVolumesPerFrame[nStartPos];
    
    for (int i = 1; i < MAX_VOLUME_CNT; i++) {
        bool bInc = m_maxVolumesPerFrame[(nStartPos + i + 1) % MAX_VOLUME_CNT] > m_maxVolumesPerFrame[(nStartPos + i) % MAX_VOLUME_CNT];
        if (bPrevIsInc && !bInc) {
            maxPosArray[maxPosArrayCnt++] = i;
        } else if (!bPrevIsInc && bInc) {
            minPosArray[minPosArrayCnt++] = i;
        }
        bPrevIsInc = bInc;
    }
    
    int nMinPos = 0;
    int nMaxPos = 0;
    
    int nScreamStartPos = ((m_nMaxVolPos - 1 - m_nUnivEngineFrameCnt) + MAX_VOLUME_CNT) % MAX_VOLUME_CNT;
    
    for (int i = 0; i < minPosArrayCnt; i++) {
        nMinPos = minPosArray[i];
        if (nMinPos >= nScreamStartPos) {
            break;
        }
    }
    
    for (int i = 0; i < maxPosArrayCnt; i++) {
        nMaxPos = maxPosArray[i];
        if (nMaxPos >= nScreamStartPos && nMaxPos > nMinPos) {
            break;
        }
    }
    
    if ((nMaxPos - nMinPos) >= 2 && (nMaxPos - nMinPos) <= 5) {
        return true;
    }
    
    return false;
}
