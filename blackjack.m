function blackjack()

    set(0,'DefaultFigureWindowStyle','docked')
    rng(3141,'twister');

    fclose all;
    close all;
    clear
    clc;
    
    ACTION_HIT = 0;
    ACTION_STAND = 1;
    actions = [ACTION_HIT, ACTION_STAND];
    
    policyDealer=zeros(22,1);
    for i=17:21
        policyDealer(i)=ACTION_STAND;
    end
    
    stateActionValues = monteCarloES(1e6,policyDealer,actions);
    stateValueUsableAce = zeros(10, 10);
    stateValueNoUsableAce = zeros(10, 10);
    actionUsableAce = zeros(10, 10);
    actionNoUsableAce = zeros(10, 10);
    for i=1:10
        for j=1:10
            [a,b]=max(stateActionValues(i,j,1,:));
            stateValueNoUsableAce(i,j)=a;
            actionNoUsableAce(i,j)=b;
            [a,b]=max(stateActionValues(i,j,2,:));
            stateValueUsableAce(i,j)=a;
            actionUsableAce(i,j)=b;
        end
    end
    surf(stateValueNoUsableAce);
    figure();
    surf(stateValueUsableAce);
    figure();
    surf(actionNoUsableAce);
    figure();
    surf(actionUsableAce);

end

function uh=targetPolicyPlayer_2(usableAce, playerSum, dealerCard,stateActionValues,stateActionPairCount)
    
    playerSum=playerSum-12;
    dealerCard=dealerCard-1;
    values1=stateActionValues(playerSum+1,dealerCard+1,usableAce+1,:);
    values2=stateActionPairCount(playerSum+1,dealerCard+1,usableAce+1,:);
    values=values1./values2;
    uh1=values(:,:,1,1);
    uh2=values(:,:,1,2);

    if uh1==uh2
        uh=floor(0+(2-0)*rand(1));
    elseif uh1>uh2
        uh=0;
    elseif uh1<uh2
        uh=1;
    else
        disp();
    end 
end


function card=getCard()
   
    card=floor(1+14*rand(1));
    card=min(card,10);
    disp('');
end


function uh=monteCarloES(nEpisodes,policyDealer,actions)
   
    stateActionValues = zeros(10, 10, 2, 2);
    stateActionPairCount = ones(10, 10, 2, 2);

    for episode=0:nEpisodes
        if mod(episode,10000) == 0
            fprintf('%i\n', episode);
        end

        tmp1=floor(0+(2-0)*rand(1));
        tmp2=floor(12+(22-12)*rand(1));
        tmp3=floor(1+(11-1)*rand(1));
        tmp4=floor(0+(2-0)*rand(1));
        
        initialState=[tmp1,tmp2,tmp3];
        initialAction=actions(tmp4+1);
        
        [~,reward, trajectory] = play_2(policyDealer,actions, initialState, initialAction,stateActionValues,stateActionPairCount);
        [a,b]=size(trajectory);
        for cont=1:a
            action=trajectory(cont,1);
            usableAce = trajectory(cont,2);
            playerSum = trajectory(cont,3)-12;
            dealerCard= trajectory(cont,4)-1;
            stateActionValues(playerSum+1, dealerCard+1, usableAce+1, action+1) = stateActionValues(playerSum+1, dealerCard+1, usableAce+1, action+1)+reward;
            stateActionPairCount(playerSum+1, dealerCard+1, usableAce+1,action+1) =stateActionPairCount(playerSum+1, dealerCard+1, usableAce+1, action+1)+ 1;
        end
    end
    uh= stateActionValues./ stateActionPairCount;
end

function [uh1,uh2,uh3]=play_2(policyDealer,actions, initialState, initialAction,stateActionValues,stateActionPairCount)

    playerSum = 0;
    playerTrajectory = [];
    usableAcePlayer = 0;

    dealerCard1 = 0;
    dealerCard2 = 0;
    usableAceDealer = 0;

    if isnan(initialState)==1
        numOfAce = 0;
        while playerSum < 12
            card = getCard();
            if card == 1
                numOfAce =numOfAce+ 1;
                card = 11;
                usableAcePlayer = 1;
            end
            playerSum =playerSum+ card;
        end
        if playerSum > 21
            playerSum =playerSum- 10;
            if numOfAce == 1
                usableAcePlayer = 0;
            end
        end
        dealerCard1 = getCard();
        dealerCard2 = getCard();
    else
        usableAcePlayer = initialState(1);
        playerSum = initialState(2);
        dealerCard1 = initialState(3);
        dealerCard2 = getCard();
    end
    state = [usableAcePlayer, playerSum, dealerCard1];
    dealerSum = 0;
    if dealerCard1 == 1 && dealerCard2 ~= 1
        dealerSum =dealerSum+ 11 + dealerCard2;
        usableAceDealer = 1;
    elseif dealerCard1 ~= 1 && dealerCard2 == 1
        dealerSum =dealerSum+ dealerCard1 + 11;
        usableAceDealer = 1;
    elseif dealerCard1 == 1 && dealerCard2 == 1
        dealerSum =dealerSum+ 1 + 11;
        usableAceDealer = 1;
    else
        dealerSum =dealerSum+ dealerCard1 + dealerCard2;
    end
    
    salida=0;
    while salida==0
        if isnan(initialAction)==0
            action = initialAction;
            initialAction = NaN;
        else
            action=targetPolicyPlayer_2(usableAcePlayer, playerSum, dealerCard1,stateActionValues,stateActionPairCount);
        end
         playerTrajectory=[playerTrajectory;action,usableAcePlayer, playerSum, dealerCard1];

        if action ==  actions(2)
            salida=1;
        else
            playerSum =playerSum+ getCard();
            if playerSum > 21
                if usableAcePlayer == 1
                    playerSum =playerSum- 10;
                    usableAcePlayer = 0;
                else
                    uh1= state;
                    uh2= -1;
                    uh3=playerTrajectory;
                    return;
                end
            end
        end
    end
    salida=0;
    while salida==0
        action = policyDealer(dealerSum);
        if action == actions(2)
            salida=1;
        else
            dealerSum =dealerSum+ getCard();
            if dealerSum > 21
                if usableAceDealer == 1
                    dealerSum =dealerSum- 10;
                    usableAceDealer = 0;
                else
                    uh1= state;
                    uh2= 1;
                    uh3=playerTrajectory;
                    return
                end
            end
        end
    end
    if playerSum > dealerSum
        uh1= state;
        uh2= 1;
        uh3= playerTrajectory;
    elseif playerSum == dealerSum
        uh1=state;
        uh2=0;
        uh3=playerTrajectory;
    else
        uh1= state;
        uh2= -1;
        uh3=playerTrajectory;
    end
end









