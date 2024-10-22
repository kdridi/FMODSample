/*==============================================================================
Event 3D Example
Copyright (c), Firelight Technologies Pty, Ltd 2012-2014.

This example demonstrates how to position events in 3D for spatialization.
==============================================================================*/
#include "fmod_studio.hpp"
#include "fmod.hpp"
#include "fmod_errors.h"
#include "common.h"

const int SCREEN_WIDTH = NUM_COLUMNS;
const int SCREEN_HEIGHT = 16;

int currentScreenPosition = -1;
char screenBuffer[(SCREEN_WIDTH + 1) * SCREEN_HEIGHT + 1] = {0};

void initializeScreenBuffer();
void updateScreenPosition(const FMOD_VECTOR& worldPosition);

int FMOD_Main()
{
    void *extraDriverData = 0;
    Common_Init(&extraDriverData);

    FMOD::Studio::System system;
    FMOD_RESULT result = FMOD::Studio::System::create(&system);
    ERRCHECK(result);

    result = system.initialize(32, FMOD_STUDIO_INIT_NORMAL, FMOD_INIT_NORMAL, extraDriverData);
    ERRCHECK(result);

    FMOD::Studio::Bank masterBank;
    ERRCHECK( system.loadBankFile(Common_MediaPath("Master Bank.bank"), &masterBank) );

    FMOD::Studio::Bank stringsBank;
    ERRCHECK( system.loadBankFile(Common_MediaPath("Master Bank.bank.strings"), &stringsBank) );

    FMOD::Studio::Bank vehiclesBank;
    ERRCHECK( system.loadBankFile(Common_MediaPath("Vehicles.bank"), &vehiclesBank) );
    
    FMOD::Studio::ID eventID = {0};
    ERRCHECK( system.lookupEventID("/Vehicles/Basic Engine", &eventID) );

    FMOD::Studio::EventDescription eventDescription;
    ERRCHECK( system.getEvent(&eventID, FMOD_STUDIO_LOAD_BEGIN_NOW, &eventDescription) );

    FMOD::Studio::EventInstance eventInstance;
    ERRCHECK( eventDescription.createInstance(&eventInstance) );

    FMOD::Studio::ParameterInstance rpm;
    ERRCHECK( eventInstance.getParameter("RPM", &rpm) );

    ERRCHECK( rpm.setValue(650) );

    ERRCHECK( eventInstance.start() );

    // Position the listener at the origin
    FMOD_3D_ATTRIBUTES attributes = { { 0 } };
    attributes.forward.z = 1.0f;
    attributes.up.y = 1.0f;
    ERRCHECK( system.setListenerAttributes(&attributes) );

    // Position the event 2 units in front of the listener
    attributes.position.z = 2.0f;
    ERRCHECK( eventInstance.set3DAttributes(&attributes) );
    
    initializeScreenBuffer();

    do
    {
        Common_Update();
        
        if (Common_BtnPress(BTN_LEFT))
        {
            attributes.position.x -= 1.0f;
            ERRCHECK( eventInstance.set3DAttributes(&attributes) );
        }
        
        if (Common_BtnPress(BTN_RIGHT))
        {
            attributes.position.x += 1.0f;
            ERRCHECK( eventInstance.set3DAttributes(&attributes) );
        }
        
        if (Common_BtnPress(BTN_UP))
        {
            attributes.position.z += 1.0f;
            ERRCHECK( eventInstance.set3DAttributes(&attributes) );
        }
        
        if (Common_BtnPress(BTN_DOWN))
        {
            attributes.position.z -= 1.0f;
            ERRCHECK( eventInstance.set3DAttributes(&attributes) );
        }

        result = system.update();
        ERRCHECK(result);
        
        updateScreenPosition(attributes.position);
        Common_Draw("==================================================");
        Common_Draw("Event 3D Example.");
        Common_Draw("Copyright (c) Firelight Technologies 2014-2014.");
        Common_Draw("==================================================");
        Common_Draw(screenBuffer);
        Common_Draw("Use the arrow keys (%s, %s, %s, %s) to control the event position", 
            Common_BtnStr(BTN_LEFT), Common_BtnStr(BTN_RIGHT), Common_BtnStr(BTN_UP), Common_BtnStr(BTN_DOWN));
        Common_Draw("Press %s to quit", Common_BtnStr(BTN_QUIT));

        Common_Sleep(50);
    } while (!Common_BtnPress(BTN_QUIT));

    result = system.release();
    ERRCHECK(result);

    Common_Close();

    return 0;
}

void initializeScreenBuffer()
{
    memset(screenBuffer, ' ', sizeof(screenBuffer));

    int idx = SCREEN_WIDTH;
    for (int i = 0; i < SCREEN_HEIGHT; ++i)
    {
        screenBuffer[idx] = '\n';
        idx += SCREEN_WIDTH + 1;
    }

    screenBuffer[(SCREEN_WIDTH + 1) * SCREEN_HEIGHT] = '\0';
}

int getCharacterIndex(const FMOD_VECTOR& position)
{
    int row = static_cast<int>(-position.z + (SCREEN_HEIGHT / 2));
    int col = static_cast<int>(position.x + (SCREEN_WIDTH / 2));
    
    if (0 < row && row < SCREEN_HEIGHT && 0 < col && col < SCREEN_WIDTH)
    {
        return (row * (SCREEN_WIDTH + 1)) + col;
    }
    
    return -1;
}

void updateScreenPosition(const FMOD_VECTOR& eventPosition)
{
    if (currentScreenPosition != -1)
    {
        screenBuffer[currentScreenPosition] = ' ';
        currentScreenPosition = -1;
    }

    FMOD_VECTOR origin = {0};
    int idx = getCharacterIndex(origin);
    screenBuffer[idx] = '^';
    
    idx = getCharacterIndex(eventPosition);    
    if (idx != -1)
    {
        screenBuffer[idx] = 'o';
        currentScreenPosition = idx;
    }
}
