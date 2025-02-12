//+------------------------------------------------------------------+
//|                                                    BREAKEVEN.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>
CTrade trade;

ulong posTicket(int index) { return PositionGetTicket(index); }
string posSymbol() { return PositionGetString(POSITION_SYMBOL); }
int posType() { return (int)PositionGetInteger(POSITION_TYPE); }

double Ask() { return NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits); }
double Bid() { return NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits); }

double posOpen_Prc() { return PositionGetDouble(POSITION_PRICE_OPEN); }
double posSL() { return PositionGetDouble(POSITION_SL); }
double posTP() { return PositionGetDouble(POSITION_TP); }

double BreakEven_After_Pts = 50;
double BreakEven_At_Pts = 30;

int Trail_Stop = 100;
int Trail_Step = 50;
int Trail_Gap = 50;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---
   // Check for existing open orders
   if (PositionsTotal() == 0)
     {
      // Open a buy order
      if(!trade.Buy(0.01))
        {
         Print("Error opening buy order: ", trade.ResultRetcode());
        }

      // Open a sell order
      if(!trade.Sell(0.01))
        {
         Print("Error opening sell order: ", trade.ResultRetcode());
        }
     }
   BreakEven();
   TrailingStop();
}
//+------------------------------------------------------------------+
void BreakEven() {
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong tkt = posTicket(i);
      if (tkt > 0) {
         if (posSymbol() == _Symbol) {
            if (BreakEven_After_Pts > 0) {
               if (posType() == POSITION_TYPE_BUY) {
                  // Buy Position
                  Print("Checking Buy Position: Ticket = ", tkt);
                  Print("Bid = ", Bid(), ", Open Price = ", posOpen_Prc(), ", BreakEven After = ", BreakEven_After_Pts * _Point);
                  if (Bid() >= posOpen_Prc() + BreakEven_After_Pts * _Point) {
                     Print("Buy Position reached Breakeven After Points");
                     if (posOpen_Prc() + BreakEven_At_Pts * _Point > posSL()) {
                        if (trade.PositionModify(tkt, posOpen_Prc() + BreakEven_At_Pts * _Point, posTP())) {
                           Print("===== BREAKEVEN (BUY) Applied @ Price ", NormalizeDouble(posOpen_Prc() + BreakEven_At_Pts * _Point, _Digits), " =====");
                        } else {
                           Print("Error modifying position for BREAKEVEN (BUY): ", trade.ResultRetcode());
                        }
                     } else {
                        Print("Buy Position SL is already higher than Breakeven level.");
                     }
                  }
               } else if (posType() == POSITION_TYPE_SELL) {
                  // Sell Position
                  Print("Checking Sell Position: Ticket = ", tkt);
                  Print("Ask = ", Ask(), ", Open Price = ", posOpen_Prc(), ", BreakEven After = ", BreakEven_After_Pts * _Point);
                  if (Ask() <= posOpen_Prc() - BreakEven_After_Pts * _Point) {
                     Print("Sell Position reached Breakeven After Points");
                     double newSL = posOpen_Prc() - BreakEven_At_Pts * _Point;
                     Print("New SL (Sell) = ", newSL, ", Current SL = ", posSL());
                     if (newSL < posSL() || posSL() == 0.0) {
                        if (trade.PositionModify(tkt, newSL, posTP())) {
                           Print("===== BREAKEVEN (SELL) Applied @ Price ", NormalizeDouble(newSL, _Digits), " =====");
                        } else {
                           Print("Error modifying position for BREAKEVEN (SELL): ", trade.ResultRetcode());
                        }
                     } else {
                        Print("Sell Position SL is already lower than Breakeven level.");
                     }
                  }
               }
            }
         }
      }
   }
}







void TrailingStop() {
   double buySL = Bid() - Trail_Stop * _Point;
   double sellSL = Ask() + Trail_Stop * _Point;

   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong tkt = posTicket(i);
      if (tkt > 0) {
         if (posSymbol() == _Symbol) {
            if (posType() == POSITION_TYPE_BUY) {
               if (buySL - Trail_Gap * _Point > posOpen_Prc() && (posSL() == 0 || buySL > posSL()) && buySL > posSL() + Trail_Step * _Point) {
                  trade.PositionModify(tkt, buySL, posTP());
                  Print("===== TRAIL STOP (BUY) Applied @ Price ", buySL, " =====");
               }
            } else if (posType() == POSITION_TYPE_SELL) {
               if (sellSL + Trail_Gap * _Point < posOpen_Prc() && (posSL() == 0 || sellSL < posSL()) && sellSL < posSL() - Trail_Step * _Point) {
                  trade.PositionModify(tkt, sellSL, posTP());
                  Print("===== TRAIL STOP (SELL) Applied @ Price ", sellSL, " =====");
               }
            }
         }
      }
   }
}
