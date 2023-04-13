%% Calculate Data
clear all; clc
datapath=('Y:\EEG_Data\PDDys\BEH\');
cd(datapath);

subjcount=0;
for subno=[8010,8070,8060,890:914];
    for session=1
        
        subjcount=subjcount+1;
        disp(['Subno: ',num2str(subno),'  Session: ',num2str(session)]); disp(' ');
        
        MEGA_ID(subjcount,:)=[subno,session];
        
        % TRAIN
        % each will have varied number of rows
        B1=load([num2str(subno),'_B1_Session',num2str(session),'_CC_train.mat']);
        B2=load([num2str(subno),'_B2_Session',num2str(session),'_CC_train.mat']);
        B3=load([num2str(subno),'_B3_Session',num2str(session),'_CC_train.mat']);
        B4=load([num2str(subno),'_B4_Session',num2str(session),'_CC_train.mat']);
        
        % ----- Columns are: -----
        %   1=data_block
        %   2=count
        % 3=type (1=A, 2=B, 3=C, 4=D)
        % 4=color (1=left, 2=right)
        % 5=congru (1=congru, 2=incongru)
        %   6=to be rewarded or not (?)
        %   7=response (1=resp, -1=noresp)
        %   8=selected_a_stim (1=yes, 0=no)  (I don't really know why this is here)
        %  9=RT
        % 10=acc (-1=tooslow, 0=incor, 1=cor)
        % 11=feedback (-3=error/tooslow, 0, 1)
        
        for bi=1:4
            PEslow{bi}=[];
        end
        for ai=1:4
            if     ai==1, data4display=B1.data_block; Block='1';
            elseif ai==2, data4display=B2.data_block; Block='2';
            elseif ai==3, data4display=B3.data_block; Block='3';
            elseif ai==4, data4display=B4.data_block; Block='4';
            end
            
            % Account for -3's
            slowcount=0; errcount=0; errrt=0; err_p_incong=0.01; % so 0 is no errors, 0.01 could be 1 congru error
            for bi=1:size(data4display,1)
                if data4display(bi,11)==-3 % if error/tooslow
                    if data4display(bi,10)==-1 % too slow
                        slowcount=slowcount+1;
                    elseif data4display(bi,10)==0 % error
                        errcount=errcount+1;
                        errrt=errrt + data4display(bi,9);
                        err_p_incong=err_p_incong + data4display(bi,5)-1;  % 1 is cong / 2 is incong
                    end
                end
            end
            errrt=errrt / errcount;
            err_p_incong=err_p_incong / errcount;
            if isinf(err_p_incong), err_p_incong=0; end
            
            if any(data4display(:,11)==-3)
                PEidx=[0;0+(data4display(:,11)==-3)];
                PEidx=PEidx(1:end-1);
                PEslow{ai}=data4display(logical(PEidx),9);
            end
            
            if ai==1,     FORMODEL_TRN{subjcount}=data4display;
            elseif ai==2, FORMODEL_TRN{subjcount}=[FORMODEL_TRN{subjcount};data4display];
            elseif ai==3, FORMODEL_TRN{subjcount}=[FORMODEL_TRN{subjcount};data4display];
            elseif ai==4, FORMODEL_TRN{subjcount}=[FORMODEL_TRN{subjcount};data4display];
            end
            
            % NOW Corrects only - after FORMODEL (should be 80)
            data4display=data4display(data4display(:,11)~=-3,:);
            
            CongRT=mean(data4display(data4display(:,5)==1,9));
            IncongRT=mean(data4display(data4display(:,5)==2,9));
            
            MEGA_TRN(subjcount,ai,:)=[subno,slowcount,errcount,errrt*1000,CongRT*1000,IncongRT*1000,err_p_incong];
            
            clear data4display Block slowcount errcount errrt CongRT IncongRT err_p_incong PEidx;
        end
        clear data_* randx_*;
        
        % TEST
        T1=load([num2str(subno),'_B1_Session',num2str(session),'_CC_test.mat']);
        T2=load([num2str(subno),'_B2_Session',num2str(session),'_CC_test.mat']);
        T3=load([num2str(subno),'_B3_Session',num2str(session),'_CC_test.mat']);
        T4=load([num2str(subno),'_B4_Session',num2str(session),'_CC_test.mat']);
        
        %   1=data_block
        %   2=count
        %   3=stimset
        %   4=response (1=resp, -1=noresp)
        %   5=resp key 68=left, 75=right
        %   6=RT
        %   7=acc (1,0,-1 for no resp)
        
        % % % % %         left_key=68;
        % % % % %         right_key=75;
        
        for ai=1:4
            if     ai==1, data4display=T1.data_test; Block='1'; div=48;
            elseif ai==2, data4display=T2.data_test; Block='2'; div=48;
            elseif ai==3, data4display=T3.data_test; Block='3'; div=48;
            elseif ai==4, data4display=T4.data_test; Block='4'; div=48;
            end
            
            temp=num2str(data4display(:,3));
            data4display(:,4)=str2num(temp(:,2));
            data4display(:,3)=str2num(temp(:,1));
            clear temp;
            
            % % % % % % % % % % % % % % %             % Fix accuracy due to prob in stim script
            % % % % % % % % % % % % % % %             if subno==101
            % % % % % % % % % % % % % % %                 for correcti=1:size(data4display,1)
            % % % % % % % % % % % % % % %                     if data4display(correcti,3)<data4display(correcti,4)
            % % % % % % % % % % % % % % %                         if data4display(correcti,5)==left_key,
            % % % % % % % % % % % % % % %                             data4display(correcti,7)=1;
            % % % % % % % % % % % % % % %                         else data4display(correcti,7)=0;
            % % % % % % % % % % % % % % %                         end
            % % % % % % % % % % % % % % %                     elseif data4display(correcti,4)<data4display(correcti,3)
            % % % % % % % % % % % % % % %                         if data4display(correcti,5)==right_key,
            % % % % % % % % % % % % % % %                             data4display(correcti,7)=1;
            % % % % % % % % % % % % % % %                         else data4display(correcti,7)=0;
            % % % % % % % % % % % % % % %                         end
            % % % % % % % % % % % % % % %                     end
            % % % % % % % % % % % % % % %                 end
            % % % % % % % % % % % % % % %             end
            
            
            if ai==1,     Block='1';
                FORMODEL_TEST{subjcount}=data4display;
            elseif ai==2, Block='2';
                FORMODEL_TEST{subjcount}=[FORMODEL_TEST{subjcount};data4display];
            elseif ai==3, Block='3';
                FORMODEL_TEST{subjcount}=[FORMODEL_TEST{subjcount};data4display];
            elseif ai==4, Block='4';
                FORMODEL_TEST{subjcount}=[FORMODEL_TEST{subjcount};data4display];
            end
            
            
            Au=data4display(data4display(:,3)==1,[4,6,7]);
            Bu=data4display(data4display(:,3)==2,[4,6,7]);
            Cu=data4display(data4display(:,3)==3,[4,6,7]);
            Du=data4display(data4display(:,3)==4,[4,6,7]);
            Ad=data4display(data4display(:,4)==1,[3,6,7]);
            Bd=data4display(data4display(:,4)==2,[3,6,7]);
            Cd=data4display(data4display(:,4)==3,[3,6,7]);
            Dd=data4display(data4display(:,4)==4,[3,6,7]);
            Aagg=[Au;Ad]; Bagg=[Bu;Bd]; Cagg=[Cu;Cd]; Dagg=[Du;Dd];
            clear Au Bu Cu Du Ad Bd Cd Dd;
            % no 99's
            Aagg=Aagg(Aagg(:,3)~=99,:);
            Bagg=Bagg(Bagg(:,3)~=99,:);
            Cagg=Cagg(Cagg(:,3)~=99,:);
            Dagg=Dagg(Dagg(:,3)~=99,:);
            % Acc
            AB=sum(Aagg(Aagg(:,1)==2,3)) ./ length(Aagg(Aagg(:,1)==2,3)) ;
            AC=sum(Aagg(Aagg(:,1)==3,3)) ./ length(Aagg(Aagg(:,1)==3,3)) ;
            AD=sum(Aagg(Aagg(:,1)==4,3)) ./ length(Aagg(Aagg(:,1)==4,3)) ;
            BC=sum(Bagg(Bagg(:,1)==3,3)) ./ length(Bagg(Bagg(:,1)==3,3)) ; % CC choices
            BD=sum(Bagg(Bagg(:,1)==4,3)) ./ length(Bagg(Bagg(:,1)==4,3)) ;
            CD=sum(Cagg(Cagg(:,1)==4,3)) ./ length(Cagg(Cagg(:,1)==4,3)) ;
            % RT
            AB_rt = mean(Aagg(Aagg(:,1)==2,2)) *1000 ;
            AC_rt = mean(Aagg(Aagg(:,1)==3,2)) *1000 ;
            AD_rt = mean(Aagg(Aagg(:,1)==4,2)) *1000 ;
            BC_rt = mean(Bagg(Bagg(:,1)==3,2)) *1000 ;
            BD_rt = mean(Bagg(Bagg(:,1)==4,2)) *1000 ;
            CD_rt = mean(Cagg(Cagg(:,1)==4,2)) *1000 ;
            
            % Aggregate
            MEGA_ACC(subjcount,ai,1)=AB; MEGA_ACC(subjcount,ai,2)=AC; MEGA_ACC(subjcount,ai,3)=AD;
            MEGA_ACC(subjcount,ai,4)=BC; MEGA_ACC(subjcount,ai,5)=BD; MEGA_ACC(subjcount,ai,6)=CD;
            MEGA_RT(subjcount,ai,1)=AB_rt; MEGA_RT(subjcount,ai,2)=AC_rt; MEGA_RT(subjcount,ai,3)=AD_rt;
            MEGA_RT(subjcount,ai,4)=BC_rt; MEGA_RT(subjcount,ai,5)=BD_rt; MEGA_RT(subjcount,ai,6)=CD_rt;
            % RT by Acc
            Aagg_c = Aagg(Aagg(:,3)==1,:);  Aagg_i = Aagg(Aagg(:,3)==0,:);
            Bagg_c = Bagg(Bagg(:,3)==1,:);  Bagg_i = Bagg(Bagg(:,3)==0,:);
            Cagg_c = Cagg(Cagg(:,3)==1,:);  Cagg_i = Cagg(Cagg(:,3)==0,:);
            AB_crt = mean(Aagg_c(Aagg_c(:,1)==2,2)) *1000 ;  AB_irt = mean(Aagg_i(Aagg_i(:,1)==2,2)) *1000 ;
            AC_crt = mean(Aagg_c(Aagg_c(:,1)==3,2)) *1000 ;  AC_irt = mean(Aagg_i(Aagg_i(:,1)==3,2)) *1000 ;
            AD_crt = mean(Aagg_c(Aagg_c(:,1)==4,2)) *1000 ;  AD_irt = mean(Aagg_i(Aagg_i(:,1)==4,2)) *1000 ;
            BC_crt = mean(Bagg_c(Bagg_c(:,1)==3,2)) *1000 ;  BC_irt = mean(Bagg_i(Bagg_i(:,1)==3,2)) *1000 ;
            BD_crt = mean(Bagg_c(Bagg_c(:,1)==4,2)) *1000 ;  BD_irt = mean(Bagg_i(Bagg_i(:,1)==4,2)) *1000 ;
            CD_crt = mean(Cagg_c(Cagg_c(:,1)==4,2)) *1000 ;  CD_irt = mean(Cagg_i(Cagg_i(:,1)==4,2)) *1000 ;
            % Aggregate
            MEGA_RT_c(subjcount,ai,1)=AB_crt; MEGA_RT_c(subjcount,ai,2)=AC_crt; MEGA_RT_c(subjcount,ai,3)=AD_crt;
            MEGA_RT_c(subjcount,ai,4)=BC_crt; MEGA_RT_c(subjcount,ai,5)=BD_crt; MEGA_RT_c(subjcount,ai,6)=CD_crt;
            MEGA_RT_i(subjcount,ai,1)=AB_irt; MEGA_RT_i(subjcount,ai,2)=AC_irt; MEGA_RT_i(subjcount,ai,3)=AD_irt;
            MEGA_RT_i(subjcount,ai,4)=BC_irt; MEGA_RT_i(subjcount,ai,5)=BD_irt; MEGA_RT_i(subjcount,ai,6)=CD_irt;
            
            % display accuracy
            % disp(['Block: ',Block, ' Total Acc: ',num2str((sum(data4display(data4display(:,8)~=99,8))/div)*100),'%']);
            disp(['Block: ',Block, ' Easy Acc: ',num2str(AD*100),'%']);
            disp(['Block: ',Block, ' Simple CC Acc: ',num2str(BC*100),'%']);
            disp(['Block: ',Block, ' Relative CC Acc: ',num2str(((AC-AB)+(BD-CD))*100),'%']);
            disp([' ']);
            
            clear *agg* AB AC AD BC BD CD data4display data4* *_rt *_crt *_irt;
            
        end
        
        
        PEslow_agg=0;
        
        for bi=1:4
            PEslow_agg=[PEslow_agg;PEslow{bi}];
        end
        MEGA_PE(subjcount,:)=mean(PEslow_agg(2:end));
        clear Data* PE*
        
        disp(['ERRORS (ERNs): ',num2str(sum(MEGA_TRN(subjcount,:,3)))]);
        disp([' ']);
        
    end
end

save('CC_Behavior_CTL.mat','MEGA_ACC','MEGA_RT','MEGA_RT_c','MEGA_RT_i','MEGA_TRN','MEGA_PE','MEGA_ID');
save('CC_FORMODEL_CTL.mat','FORMODEL_TRN','FORMODEL_TEST');

%%
clear all; clc
datapath=('Y:\EEG_Data\PDDys\BEH\');
cd(datapath);

load('CC_Behavior_CTL.mat');
SUBJS=unique(MEGA_ID(:,1));

for ai=1:size(MEGA_ID,1)
        CTL.ID(ai,:)=SUBJS(ai);
        CTL.PE(ai,:)=MEGA_PE(ai);
        
        CTL.slows(ai,:)=squeeze(MEGA_TRN(ai,:,2));
        CTL.errs(ai,:)=squeeze(MEGA_TRN(ai,:,3));
        CTL.err_rt(ai,:)=squeeze(MEGA_TRN(ai,:,4));
        CTL.cong_rt(ai,:)=squeeze(MEGA_TRN(ai,:,5));
        CTL.incong_rt(ai,:)=squeeze(MEGA_TRN(ai,:,6));
        CTL.err_p_incong(ai,:)=squeeze(MEGA_TRN(ai,:,7));
        CTL.CongruEffect(ai,:)=CTL.incong_rt(ai,:)-CTL.cong_rt(ai,:);
        %
        CTL.EASY(ai,:)=         MEGA_ACC(ai,:,3) ;
        CTL.Direct_CC(ai,:) =   MEGA_ACC(ai,:,4) ;
        CTL.Indirect_CC(ai,:) = (MEGA_ACC(ai,:,2)-MEGA_ACC(ai,:,1)) + (MEGA_ACC(ai,:,5)-MEGA_ACC(ai,:,6)) ;
        CTL.EASY_RT(ai,:) =     MEGA_RT(ai,:,3) ;
        CTL.Direct_CC_RT(ai,:) = MEGA_RT(ai,:,4) ;
        CTL.Indirect_CC_RT(ai,:) = (MEGA_RT(ai,:,1)-MEGA_RT(ai,:,2)) + (MEGA_RT(ai,:,5)-MEGA_RT(ai,:,6)) ;
        %
        CTL.EASY_cRT(ai,:) =        MEGA_RT_c(ai,:,3) ;
        CTL.Direct_CC_cRT(ai,:) =   MEGA_RT_c(ai,:,4) ;
        CTL.Indirect_CC_cRT(ai,:) = (MEGA_RT_c(ai,:,1)-MEGA_RT_c(ai,:,2)) + (MEGA_RT_c(ai,:,5)-MEGA_RT_c(ai,:,6)) ;
        CTL.EASY_iRT(ai,:) =        MEGA_RT_i(ai,:,3) ;
        CTL.Direct_CC_iRT(ai,:) =   MEGA_RT_i(ai,:,4) ;
        CTL.Indirect_CC_iRT(ai,:) = (MEGA_RT_i(ai,:,1)-MEGA_RT_i(ai,:,2)) + (MEGA_RT_i(ai,:,5)-MEGA_RT_i(ai,:,6)) ;
end

save('BEH_CC_CTL.mat','CTL')

%%
CC_TRNHDR={'subno','slowcount','errcount','errrt','CongRT','IncongRT'};
BigN=size(CTL.ID,1);
noise=rand(1,BigN)./100;

figure
subplot(2,3,1)
hold on
boxplot(sum(CTL.errs,2))
set(gca,'xlim',[0 2],'xtick',[1:1:1],'xticklabel',{'CTL'});
title('Error Ct');
subplot(2,3,2)
hold on
bar(1,mean(nanmean(CTL.err_rt,2)),.4,'g','Linewidth',2); errorbar(1,mean(nanmean(CTL.err_rt,2)),std(nanmean(CTL.err_rt,2))./sqrt(BigN),'k:','Linewidth',2);
bar(2,mean(nanmean(CTL.cong_rt,2)),.4,'g','Linewidth',2); errorbar(2,mean(nanmean(CTL.cong_rt,2)),std(nanmean(CTL.cong_rt,2))./sqrt(BigN),'k:','Linewidth',2);
bar(3,mean(nanmean(CTL.incong_rt,2)),.4,'g','Linewidth',2); errorbar(3,mean(nanmean(CTL.incong_rt,2)),std(nanmean(CTL.incong_rt,2))./sqrt(BigN),'k:','Linewidth',2);
bar(4,nanmean(CTL.PE*1000),.4,'g','Linewidth',2); errorbar(4,nanmean(CTL.PE*1000),std(CTL.PE*1000)./sqrt(BigN),'k:','Linewidth',2);
title('RTs per condition');
set(gca,'ylim',[400 650],'xlim',[0 5],'xtick',[1:1:4],'xticklabel',{'Err','Cong','Incong','PEslow'});
subplot(2,3,3)
hold on
bar(1,mean(nanmean(CTL.CongruEffect,2)),'g','Linewidth',2); errorbar(1,mean(nanmean(CTL.CongruEffect,2)),std(nanmean(CTL.CongruEffect,2))./sqrt(BigN),'k:','Linewidth',2);
set(gca,'xlim',[0 3],'xtick',[1:1:1],'xticklabel',{'CTL'});
title('Conflict');
subplot(2,3,4)
hold on
bar(1,mean(mean(CTL.EASY,2),1),.4,'g','Linewidth',2); % Easy Acc
bar(2,mean(mean(CTL.Direct_CC,2),1),.4,'g','Linewidth',2); % Direct CC
bar(3,mean(mean(CTL.Indirect_CC,2),1),.4,'g','Linewidth',2); % Indirect CC
errorbar(1,mean(mean(CTL.EASY,2),1),std(mean(CTL.EASY,2),1) ./ sqrt(BigN),'k:','Linewidth',2)
errorbar(2,mean(mean(CTL.Direct_CC,1),2),std(mean(CTL.Direct_CC,2),1) ./ sqrt(BigN),'k:','Linewidth',2)
errorbar(3,mean(mean(CTL.Indirect_CC,1),2),std(mean(CTL.Indirect_CC,2),1) ./ sqrt(BigN),'k:','Linewidth',2)
plot([0 1],[.5 .5],'b','Linewidth',5);
plot([0 1],[0 0],'r','Linewidth',5);
set(gca,'xlim',[0 4],'ylim',[-.1 1],'ytick',[-.1:.1:1],'xlim',[0 4],'xtick',[1:1:3],'xticklabel',{'EASY','SIMPLE','RELATIVE'});
ylabel('% Accuracy');
title('TOTAL Accuracy');
%
[H,P,CI,STATS]=ttest(mean(CTL.Direct_CC,2),.5);
text(.1,.95,['Simple t=',num2str(STATS.tstat),' p=',num2str(P)],'sc');
%
subplot(2,3,5)
hold on
bar(1,mean(mean(CTL.EASY_RT,2),1),.4,'g','Linewidth',2); % Easy Acc
bar(2,mean(mean(CTL.Direct_CC_RT,2),1),.4,'g','Linewidth',2); % Direct CC
errorbar(1,mean(mean(CTL.EASY_RT,2),1),std(mean(CTL.EASY_RT,2),1) ./ sqrt(BigN),'k:','Linewidth',2)
errorbar(2,mean(mean(CTL.Direct_CC_RT,2),1),std(mean(CTL.Direct_CC_RT,2),1) ./ sqrt(BigN),'k:','Linewidth',2)
set(gca,'xlim',[0 3],'xtick',[1:1:2],'xticklabel',{'Easy','Simple'});
ylabel('RT');
title('TOTAL RTs');
subplot(2,3,6)
hold on
bar(1,mean(mean(CTL.Indirect_CC_RT,2),1),'g','Linewidth',2); % Indirect CC
errorbar(1,mean(mean(CTL.Indirect_CC_RT,2),1),std(mean(CTL.Indirect_CC_RT,2),1) ./ sqrt(BigN),'k:','Linewidth',2)
text(.1,.95,'(AB-AC)+(BD-BC)','sc');
set(gca,'xlim',[0 2],'xtick',[1:1:1],'xticklabel',{'Relative'});
ylabel('RT');
title('TOTAL RTs');


%%

