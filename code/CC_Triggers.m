%% CC Triggers

TRN_STIM={'S111','S112','S113','S114','S121','S122','S123','S124','S211','S212','S213','S214','S221','S222','S223','S224'};
% TRIALCODE=strcat(num2str(color),num2str(congru),num2str(type));
% % % % Color
% % % y=1;
% % % b=2;
% % % % Congru
% % % c=1;
% % % i=2;
% % % % Stim
% % % A=1;   - A is the 100% rewarding stimulus
% % % B=2;   - B is the  50% rewarding stimulus  (conflict before reward)
% % % C=3;   - C is the  50% rewarding stimulus  (conflict before punishment)
% % % D=4;   - D is the   0% rewarding stimulus
% So: S111 would be Yellow, congruent, 'A' stim;   S223 would be Blue, incongruent, 'C' stim

TRN_RESP={'S101','S102','S103','S104'};
% 101:  left_key and correct_choice
% 102: right_key and correct_choice
% 103:  left_key and response error
% 104: right_key and response error
% 105 and 999 also exist; they are timeout and 'other', which probably is rare.

TRN_FB={'S  8','S  9'};
% 8 is reward (green +1)
% 9 is punishment (red 0)
% 7 is response timeout feedback
% 6 is error feedback

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% - Test phase

TST_STIM={'S 12','S 13','S 14','S 21','S 23','S 24','S 31','S 32','S 34','S 41','S 42','S 43'};
% TRIALCODE=strcat(num2str(L),num2str(R));
% Numbers are same as stim above (A:D = 1:4), but they are orders in Left - Right manner
% So 12 would be A B and 21 would be B A.  Make sense?


TST_RESP={'S  1','S  2','S  3','S  4'};
% 1: left_key and optimal choice (A>B>C>D)
% 2: right_key and optimal choice
% 3: left_key and suboptimal choice (A<B<C<D)
% 4: right_key and suboptimal choice
% 5: no response, timed out


