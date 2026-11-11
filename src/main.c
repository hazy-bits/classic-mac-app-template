#include <Dialogs.h>
#include <Events.h>
#include <Fonts.h>
#include <Memory.h>
#include <Menus.h>
#include <Quickdraw.h>
#include <Resources.h>
#include <Windows.h>

#ifdef CLASSIC_SMOKE_TEST
#include "classic-test.h"
#endif

enum { kAppleMenu = 128, kFileMenu = 129, kQuitItem = 1 };

static Boolean gRunning = true;

static void DrawHello(WindowRef window)
{
#if TARGET_API_MAC_CARBON
    Rect bounds;
    SetPortWindowPort(window);
    GetWindowPortBounds(window, &bounds);
#else
    SetPort(window);
    Rect bounds = window->portRect;
#endif
    BeginUpdate(window);
    EraseRect(&bounds);
    TextFont(0);
    TextSize(12);
    MoveTo(28, 48);
#if TARGET_API_MAC_CARBON
    DrawString("\pHello from Carbon.");
#else
    DrawString("\pHello from classic Mac OS.");
#endif
    EndUpdate(window);
}

static void HandleMenu(long choice)
{
    short menu = (short)(choice >> 16);
    short item = (short)(choice & 0xffff);
    if(menu == kFileMenu && item == kQuitItem)
        gRunning = false;
    HiliteMenu(0);
}

static void DispatchEvent(EventRecord *event)
{
    WindowRef window;
    short part;

    switch(event->what) {
        case mouseDown:
            part = FindWindow(event->where, &window);
            if(part == inMenuBar)
                HandleMenu(MenuSelect(event->where));
            else if(part == inGoAway && TrackGoAway(window, event->where))
                gRunning = false;
            else if(part == inDrag) {
#if TARGET_API_MAC_CARBON
                BitMap screen;
                GetQDGlobalsScreenBits(&screen);
                DragWindow(window, event->where, &screen.bounds);
#else
                DragWindow(window, event->where, &qd.screenBits.bounds);
#endif
            } else if(part == inContent && window != FrontWindow())
                SelectWindow(window);
            break;
        case keyDown:
            if(event->modifiers & cmdKey)
                HandleMenu(MenuKey(event->message & charCodeMask));
            break;
        case updateEvt:
            DrawHello((WindowRef)event->message);
            break;
    }
}

#ifdef CLASSIC_SMOKE_TEST
static int WriteTestReport(WindowRef window)
{
    ClassicTestReport report;
    if(!ClassicTestBegin(&report, 2))
        return 1;
    ClassicTestResult(&report, window != NULL, "application created a window",
                      "NewWindow returned NULL");
    ClassicTestResult(&report, window != NULL && FrontWindow() == window,
                      "application window is frontmost",
                      "FrontWindow did not return the application window");
    return ClassicTestEnd(&report);
}
#endif

int main(void)
{
    EventRecord event;
    Rect bounds = {70, 80, 260, 500};

#if !TARGET_API_MAC_CARBON
    MaxApplZone();
    InitGraf(&qd.thePort);
    InitFonts();
    InitWindows();
    InitMenus();
    InitDialogs(NULL);
#endif
    InitCursor();

    SetMenuBar(GetNewMBar(128));
#if !TARGET_API_MAC_CARBON
    AppendResMenu(GetMenu(kAppleMenu), 'DRVR');
#endif
    DrawMenuBar();

    WindowRef window = NewWindow(NULL, &bounds, "\pHelloClassic", true,
                                 documentProc, (WindowRef)-1L, true, 0);

#ifdef CLASSIC_SMOKE_TEST
    int result = WriteTestReport(window);
    if(window != NULL)
        DisposeWindow(window);
    return result;
#else
    if(window == NULL)
        return 1;
    while(gRunning) {
        if(WaitNextEvent(everyEvent, &event, 6, NULL))
            DispatchEvent(&event);
    }
    DisposeWindow(window);
    return 0;
#endif
}
